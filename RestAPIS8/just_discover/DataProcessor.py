import numpy as np
import scipy.sparse
from collections import namedtuple
import psycopg2
import creds_psql as creds
from typing import List
from collections import defaultdict

np.random.seed(seed=8)
ContextRatingPair = namedtuple("ContextRatingPair", "context rating")
ItemRatingPair = namedtuple("ItemRatingPair", "item rating")


def tree():
    return defaultdict(tree)


class RatingObj:

    def __init__(self):

        self.user_ids = dict()
        self.items_ids = dict()
        self.ctx_ids = dict()
        self.ui_ids = dict()
        self.dim_ids = dict()
        self.cond_ids = dict()

        self.ids_user = dict()
        self.ids_items = dict()
        self.ids_ctx = dict()
        self.ids_ctx_list = dict()
        self.ids_ui = dict()
        self.ids_dim = dict()
        self.ids_cond = dict()

        self.num_rating: int
        self.ui_user_ids = dict()
        self.ui_item_ids = dict()
        self.cond_dim_dict = dict()
        self.dim_cond_dict = defaultdict(set)

        self.user_item_user_ids_multimap = defaultdict(set)
        self.user_item_item_ids_multimap = defaultdict(set)

        self.context_str_ids = dict()
        self.context_condition_multimap = defaultdict(set)
        self.condition_context_multimap = defaultdict(set)
        self.ratings_count = 0
        self.rating_values = set()
        self.rate_matrix = None
        self.assign_matrix = None
        self.user_rated_item_in_ctx_multimap = tree()

        self.rating_users_multimap = tree()
        self.rating_items_multimap = tree()

        self.item_users_multimap = tree()
        self.user_rating_multimap = tree()

        self.rating_items_multimap = tree()
        self.user_item_context_rating = dict(list())
        self.ratings = defaultdict(int)

    def split_data(self, k_folds):

        ratings_count = len(self.rate_matrix.data)
        rdm = np.random.uniform(low=0.0, high=1.0, size=ratings_count)
        fold = np.empty(ratings_count)
        indv_count = ratings_count/k_folds

        for idx in range(ratings_count):
            fold[idx] = int((idx/indv_count) + 1)

        inds = rdm.argsort()
        randomised_folds = fold[inds]

        row_ptr_np_array = self.rate_matrix.indptr
        column_idx_np_array = self.rate_matrix.indices
        number_of_rows = self.rate_matrix.shape[0]
        number_of_columns = self.rate_matrix.shape[1]

        self.assign_matrix = scipy.sparse.csr_matrix((randomised_folds, column_idx_np_array, row_ptr_np_array), shape=(number_of_rows, number_of_columns), dtype=int)

    def get_kth_fold(self, k):
        train_matrix = scipy.sparse.csr_matrix.copy(self.rate_matrix)
        test_matrix = scipy.sparse.csr_matrix.copy(self.rate_matrix)

        for idx, entry in enumerate(self.assign_matrix.data):
            if entry == k:
                train_matrix.data[idx] = 0.0
            else:
                test_matrix.data[idx] = 0.0
        scipy.sparse.csr_matrix.eliminate_zeros(train_matrix)
        scipy.sparse.csr_matrix.eliminate_zeros(test_matrix)
        return train_matrix, test_matrix
        #return train_matrix.tocsc(), test_matrix.tocsc()

    def get_user_id_from_user_item_id(self, user_item_id):
        return self.ui_user_ids.get(user_item_id)

    def get_item_id_from_user_item_id(self, user_item_id):
        return self.ui_item_ids.get(user_item_id)

    def post_process_memory_for_training(self):
        self.user_rated_item_in_ctx_multimap.clear()
        self.rate_matrix = None
        self.assign_matrix = None

    def post_process_memory_for_saving(self):
        self.rate_matrix = None
        self.assign_matrix = None



    def to_traditional_sparse_rating(self, sparse_matrix):
        reviews = 0
        item_set = set()
        user_item_rating = dict()
        for idx, entry in enumerate(sparse_matrix):
            if entry.nnz is 0:
                user_id = self.get_user_id_from_user_item_id(idx)
                user_item_rating.setdefault(user_id, list())
                continue
            user_id = self.get_user_id_from_user_item_id(idx)
            item_id = self.get_item_id_from_user_item_id(idx)
            mean_rating = np.mean(entry.data)
            item_rating_pair = ItemRatingPair(item=item_id, rating=mean_rating)
            user_item_rating.setdefault(user_id, list()).append(item_rating_pair)
            reviews += 1
            item_set.add(item_id)

        number_of_users = len(self.user_ids)
        number_of_reviews = reviews
        number_of_items = len(self.items_ids)

        column_id_np_array = np.empty(number_of_reviews, dtype=int)
        row_ptr_np_array = np.empty(number_of_users + 1, dtype=int)
        row_data_np_array = np.empty(number_of_reviews)

        element_index = 0
        end_ptr = 0
        row_ptr_np_array[0] = 0
        for idx, user_row in enumerate(user_item_rating.items()):
            end_ptr += len(user_row[1])
            row_ptr_np_array[idx + 1] = end_ptr
            for item_rating_pair in user_row[1]:
                row_data_np_array[element_index] = item_rating_pair.rating
                column_id_np_array[element_index] = item_rating_pair.item
                element_index += 1

        return scipy.sparse.csr_matrix((row_data_np_array, column_id_np_array, row_ptr_np_array),
                                       shape=(number_of_users, number_of_items))

    def make_user_context_item_multimap(self, sparse_matrix):
        user_context_item_multimap = tree()

        for idx, matrix_entry in enumerate(sparse_matrix):
            if matrix_entry.nnz == 0:
                continue
            user_item_id = idx
            user_id = self.get_user_id_from_user_item_id(user_item_id)
            item_id = self.get_item_id_from_user_item_id(user_item_id)
            for inner_value in range(0, matrix_entry.nnz):
                context = matrix_entry.indices[inner_value]

                user_context_item_multimap[user_id][context][item_id] = item_id
        return user_context_item_multimap

    def make_item_set_from_sparse_matrix(self, sparse_matrix):
        item_set = set()
        for idx, entry in enumerate(sparse_matrix):
            item_set.add(self.ui_item_ids.get(idx))
        return item_set


def transform_reviews_table_to_binary():
    conn_string = "host=" + creds.PGHOST + " port=" + creds.PORT + " dbname=" + creds.PGDATABASE + " user=" + creds.PGUSER + " password=" + creds.PGPASSWORD

    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    cursor2 = conn.cursor()
    cursor.execute("SELECT COUNT (*)FROM justdiscover.reviews")
    traditional_reviews_count = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM justdiscover.reviews_binary")
    binary_reviews_count = cursor.fetchone()[0]
    cursor.execute("SELECT * FROM justdiscover.reviews_binary WHERE FALSE")
    target_columns_list = [desc[0] for desc in cursor.description[:4]]

    limit = traditional_reviews_count - binary_reviews_count
    offset = binary_reviews_count

    cursor.execute("SELECT justdiscover.reviews_backup.id, justdiscover.users.id_sk, justdiscover.reviews_backup.poi_id, justdiscover.reviews_backup.rating, justdiscover.reviews_backup.month_visited, justdiscover.reviews_backup.company FROM justdiscover.reviews_backup, justdiscover.users WHERE users.id = reviews_backup.user_id ORDER BY reviews_backup.id LIMIT %s OFFSET %s", (limit, offset))

    ctx_dims: List[str] = [desc[0] for desc in cursor.description[4:]]
    row_number = 0
    while True:
        values = list()
        row = cursor.fetchone()
        if row is None:
            break
        values.append(row[0])
        values.append(row[1])
        values.append(row[2])
        values.append(row[3].real)

        target_columns_with_context_list = list()
        for idx, ctx in enumerate(row[4:]):
            target_columns_with_context_list.append('"' + ctx_dims[idx] + ":" + ctx.split(" ")[0].lower() + '"')
            values.append(True)

        values_tuple = tuple(values)
        target_columns_str = ', '.join([str(elem) for elem in target_columns_list + target_columns_with_context_list])
        target_columns_str = "(" + target_columns_str + ") "
        query ="INSERT INTO justdiscover.reviews_binary" + target_columns_str + "VALUES %s"
        cursor2.execute(query, (values_tuple,))
        if row_number % 100000 is 0:
            conn.commit()
    conn.commit()
    conn.close()


def read_data_binary_file():
    rating_obj = RatingObj()

    with open('movielens.csv', 'r') as reader:
        line = reader.readline()
        colnames = line.split(',')[3:]
        for counter, context in enumerate(colnames):
            context_split = context.strip().split(":")
            context_dim = context_split[0]
            dimc = rating_obj.dim_ids.get(context_dim, len(rating_obj.dim_ids.keys()))
            rating_obj.dim_ids[context_dim] = dimc
            rating_obj.cond_ids[context] = counter
            rating_obj.dim_cond_dict[dimc].add(counter)
            rating_obj.cond_dim_dict[counter] = dimc

        for line in reader:
            row = line.strip().split(',')
            user = row[0]
            user_id = rating_obj.user_ids.get(user, len(rating_obj.user_ids))
            rating_obj.user_ids[user] = user_id

            item = row[1]
            item_id = rating_obj.items_ids.get(item, len(rating_obj.items_ids))
            rating_obj.items_ids[item] = item_id

            rating = float(row[2])
            rating_obj.rating_values.add(rating)
            rating_obj.ratings_count += 1
            user_item = str(user_id) + "," + str(item_id)
            user_item_id = rating_obj.ui_ids.get(user_item, len(rating_obj.ui_ids))
            rating_obj.ui_ids[user_item] = user_item_id

            rating_obj.ratings[rating] += 1
            rating_obj.ui_user_ids[user_item_id] = user_id
            rating_obj.ui_item_ids[user_item_id] = item_id

            rating_obj.user_item_user_ids_multimap[user_item_id].add(user_id)
            rating_obj.user_item_item_ids_multimap[user_item_id].add(item_id)

            # Indexing context

            condition_list: List[int] = list()
            for idx, ctx in enumerate(row[3:]):
                if ctx == '1':
                    condition_list.append(idx)

            context_str = str(condition_list)[1:-1]

            context_id = rating_obj.ctx_ids.get(context_str, len(rating_obj.ctx_ids))
            rating_obj.ctx_ids[context_str] = context_id
            rating_obj.ids_ctx[context_id] = context_str

            for condition in condition_list:
                rating_obj.condition_context_multimap[condition].add(context_id)

            context_rating_pair = ContextRatingPair(context=context_id, rating=rating)
            rating_obj.user_item_context_rating.setdefault(user_item_id, list()).append(context_rating_pair)

            rating_obj.user_rated_item_in_ctx_multimap[user_id][item_id][context_id] = rating

        for key, val in rating_obj.ids_ctx.items():
            rating_obj.ids_ctx_list[key] = [int(s) for s in val.split(',')]

        rating_obj.ids_user = dict((v, k) for k, v in rating_obj.user_ids.items())
        rating_obj.ids_items = dict((v, k) for k, v in rating_obj.items_ids.items())
        rating_obj.ids_cond = dict((v, k) for k, v in rating_obj.cond_ids.items())

        for key, val in rating_obj.ids_ctx_list.items():
            context_str = ','.join([str(rating_obj.ids_cond[elem]) for elem in val])
            rating_obj.context_str_ids[context_str] = key

        sorted(rating_obj.rating_values)
        number_of_rows = len(rating_obj.user_item_context_rating)
        number_of_row_ptrs = number_of_rows + 1
        number_of_columns = len(rating_obj.ctx_ids)

        column_id_np_array = np.empty(rating_obj.ratings_count)
        row_ptr_np_array = np.empty(number_of_row_ptrs)
        row_data_np_array = np.empty(rating_obj.ratings_count)
        row_ptr_np_array[0] = 0

        element_index = 0
        end_ptr = 0
        for idx, user_item_row in enumerate(rating_obj.user_item_context_rating.values()):
            end_ptr += len(user_item_row)
            row_ptr_np_array[idx + 1] = end_ptr
            for ctx_rate_pair in user_item_row:
                row_data_np_array[element_index] = ctx_rate_pair.rating
                column_id_np_array[element_index] = ctx_rate_pair.context
                element_index += 1

        rating_obj.items = len(rating_obj.items_ids)
        rating_obj.users = len(rating_obj.user_ids)

        rate_matrix = scipy.sparse.csr_matrix((row_data_np_array, column_id_np_array, row_ptr_np_array),
                                              shape=(number_of_rows, number_of_columns))
        rating_obj.rate_matrix = rate_matrix

        return rating_obj


def read_data_binary(min_num_ratings=1):
    rating_obj = RatingObj()
    conn_string = "host=" + creds.PGHOST + " port=" + creds.PORT + " dbname=" + creds.PGDATABASE + " user=" + creds.PGUSER + " password=" + creds.PGPASSWORD
    db = psycopg2.connect(conn_string)
    cursor = db.cursor()
    cursor.execute("SELECT * FROM justdiscover.reviews_binary WHERE user_name in (SELECT user_name FROM justdiscover.reviews_binary GROUP BY user_name having COUNT(*) >=  %s) ORDER BY reviews_binary.id ASC", (min_num_ratings,))

    colnames: List[str] = [desc[0] for desc in cursor.description[4:]]

    for counter, context in enumerate(colnames):
        context_split = context.strip().split(":")
        context_dim = context_split[0]
        dimc = rating_obj.dim_ids.get(context_dim, len(rating_obj.dim_ids.keys()))
        rating_obj.dim_ids[context_dim] = dimc
        rating_obj.cond_ids[context] = counter
        rating_obj.dim_cond_dict[dimc].add(counter)
        rating_obj.cond_dim_dict[counter] = dimc

    while True:
        row = cursor.fetchone()
        if row is None:
            break
        user = row[1]
        user_id = rating_obj.user_ids.get(user, len(rating_obj.user_ids))
        rating_obj.user_ids[user] = user_id

        item = row[2]
        item_id = rating_obj.items_ids.get(item, len(rating_obj.items_ids))
        rating_obj.items_ids[item] = item_id

        rating = row[3]
        rating_obj.rating_values.add(rating)
        rating_obj.ratings_count += 1
        user_item = str(user_id) + "," + str(item_id)
        user_item_id = rating_obj.ui_ids.get(user_item, len(rating_obj.ui_ids))
        rating_obj.ui_ids[user_item] = user_item_id

        rating_obj.ratings[rating] += 1

        rating_obj.rating_items_multimap[rating][item_id] = item_id
        rating_obj.rating_users_multimap[rating][user_id] = user_id

        rating_obj.item_users_multimap[item_id][user_id] = user_id
        rating_obj.user_rating_multimap[user_id][rating] = rating

        rating_obj.ui_user_ids[user_item_id] = user_id
        rating_obj.ui_item_ids[user_item_id] = item_id

        rating_obj.user_item_user_ids_multimap[user_item_id].add(user_id)
        rating_obj.user_item_item_ids_multimap[user_item_id].add(item_id)

        # Indexing context

        condition_list: List[int] = list()
        for idx, ctx in enumerate(row[4:]):
            if ctx:
                condition_list.append(idx)

        context_str = str(condition_list)[1:-1]

        context_id = rating_obj.ctx_ids.get(context_str, len(rating_obj.ctx_ids))
        rating_obj.ctx_ids[context_str] = context_id
        rating_obj.ids_ctx[context_id] = context_str

        for condition in condition_list:
            rating_obj.condition_context_multimap[condition].add(context_id)

        context_rating_pair = ContextRatingPair(context=context_id, rating=rating)
        rating_obj.user_item_context_rating.setdefault(user_item_id, list()).append(context_rating_pair)

        rating_obj.user_rated_item_in_ctx_multimap[user_id][item_id][context_id] = rating

    for key, val in rating_obj.ids_ctx.items():
        rating_obj.ids_ctx_list[key] = [int(s) for s in val.split(',')]

    rating_obj.ids_user = dict((v, k) for k, v in rating_obj.user_ids.items())
    rating_obj.ids_items = dict((v, k) for k, v in rating_obj.items_ids.items())
    rating_obj.ids_cond = dict((v, k) for k, v in rating_obj.cond_ids.items())

    for key, val in rating_obj.ids_ctx_list.items():
        context_str = ','.join([str(rating_obj.ids_cond[elem]) for elem in val])
        rating_obj.context_str_ids[context_str] = key

    sorted(rating_obj.rating_values)
    number_of_rows = len(rating_obj.user_item_context_rating)
    number_of_row_ptrs = number_of_rows + 1
    number_of_columns = len(rating_obj.ctx_ids)

    column_id_np_array = np.empty(rating_obj.ratings_count)
    row_ptr_np_array = np.empty(number_of_row_ptrs)
    row_data_np_array = np.empty(rating_obj.ratings_count)
    row_ptr_np_array[0] = 0

    element_index = 0
    end_ptr = 0
    for idx, user_item_row in enumerate(rating_obj.user_item_context_rating.values()):
        end_ptr += len(user_item_row)
        row_ptr_np_array[idx + 1] = end_ptr
        for ctx_rate_pair in user_item_row:
            row_data_np_array[element_index] = ctx_rate_pair.rating
            column_id_np_array[element_index] = ctx_rate_pair.context
            element_index += 1

    rating_obj.items = len(rating_obj.items_ids)
    rating_obj.users = len(rating_obj.user_ids)

    rate_matrix = scipy.sparse.csr_matrix((row_data_np_array, column_id_np_array, row_ptr_np_array),
                                          shape=(number_of_rows, number_of_columns))
    rating_obj.rate_matrix = rate_matrix

    test = rating_obj.user_rated_item_in_ctx_multimap
    rating_count = []

    for user,items in test.items():
        sum = 0
        for item in items.values():
            sum+= len(item.values())
        rating_count.append((user, sum))

    rating_count.sort(key=lambda tup: tup[1], reverse=True)

    return rating_obj


def save_dataset_to_file(rating_obj, path="dataset.csv"):
    data = rating_obj.user_rated_item_in_ctx_multimap
    column_list = ['user','item','rating']
    column_list.extend([elem for elem in rating_obj.cond_ids.keys()])
    header = ','.join(elem for elem in column_list)
    with open(path, 'w') as file:
        file.write(f'{header}\n')
        for user, items in data.items():
            user_name = rating_obj.ids_user[user]
            for item, values in items.items():
                item_id = rating_obj.ids_items[item]
                for ctx, rating in values.items():
                    line = []
                    line.append(user_name)
                    line.append(item_id)
                    line.append(rating)
                    ctx_list = rating_obj.ids_ctx_list[ctx]
                    for idx in range(len(rating_obj.cond_ids.keys())):
                        if idx in ctx_list:
                            line.append(1)
                        else:
                            line.append(0)
                    output = ','.join([str(elem) for elem in line])
                    file.write(f'{output}\n')


def balance_data(min_num_ratings_per_user=2):
    rating_obj = read_data_binary(min_num_ratings=min_num_ratings_per_user)
    ratings_num = defaultdict(lambda: 0)
    user_set = set.union(set(rating_obj.rating_users_multimap[1]), set(rating_obj.rating_users_multimap[2]))
    corrected_dict = tree()

    for u, values in rating_obj.user_rated_item_in_ctx_multimap.items():
        if u in user_set:
            corrected_dict[u] = values

    delete_poi_list = []
    poi_good = False
    user_good = False

    dict_poi = defaultdict(lambda: 0)
    for user, items in corrected_dict.items():
        for item, contexts in items.items():
            for context, rating in contexts.items():
                dict_poi[item] += 1
    for key, val in dict_poi.items():
        if val < min_num_ratings_per_user:
            delete_poi_list.append(key)
            poi_good = False

    delete_user_list= []

    while not poi_good or not user_good:
        dict_poi.clear()
        if not poi_good:
            poi_good = True
            for i in delete_poi_list:
                for user in corrected_dict:
                    corrected_dict[user].pop(i, None)
            delete_poi_list = []


            for user,items in corrected_dict.items():
                count = 0
                for item, ctx in items.items():
                    count += len(ctx.values())
                if count < min_num_ratings_per_user:
                    user_good = False
                    delete_user_list.append(user)


        if not user_good:
            user_good = True
            for i in delete_user_list:
                corrected_dict.pop(i,None)
            delete_user_list = []

            for user, items in corrected_dict.items():
                for item, contexts in items.items():
                    for context, rating in contexts.items():
                        dict_poi[item] += 1
            for key, val in dict_poi.items():
                if val < min_num_ratings_per_user:
                    delete_poi_list.append(key)
                    poi_good = False


    ratings_num.clear()
    for user, val in corrected_dict.items():
        for item, context in val.items():
            for ctx, rating in context.items():
                ratings_num[rating] += 1
    dict_poi.clear()
    for user, items in corrected_dict.items():
        for item, contexts in items.items():
            for context, rating in contexts.items():
                dict_poi[item] += 1


    rating_lowest = min([val for key,val in ratings_num.items()])
    ratings_amount_to_delete = [(key, val-rating_lowest)for key, val in ratings_num.items()]
    ratings_amount_to_delete.sort(key=lambda tup: tup[1], reverse=True)

    for rating, delete_amount in ratings_amount_to_delete:
        if delete_amount > 0:
            corrected_dict, dict_poi = __remove_ratings(corrected_dict, rating, delete_amount, dict_poi, min_num_ratings_per_user)
    rating_obj.user_rated_item_in_ctx_multimap = corrected_dict

    ratings_num.clear()
    for user, val in corrected_dict.items():
        for item, context in val.items():
            for ctx, rating in context.items():
                ratings_num[rating] += 1
    print(ratings_num)

    return rating_obj

    
def __remove_ratings(corrected_dict, rating_to_remove, remove_amount, dict_poi, min_num_ratings_per_user):
    do_remove = []
    for user, items in corrected_dict.items():
        target_rating = False
        number_of_ratings = 0
        intermediate_candidate = []
        for item, context in items.items():
            for ctx_id, rating in context.items():
                if rating == rating_to_remove:
                    target_rating = True
                    intermediate_candidate.append((user, item, ctx_id))
                number_of_ratings += 1

        if target_rating and number_of_ratings > min_num_ratings_per_user:
            for i in intermediate_candidate:
                if number_of_ratings > min_num_ratings_per_user:
                    if dict_poi[i[1]] > min_num_ratings_per_user:
                        number_of_ratings -= 1
                        do_remove.append(i)
                        dict_poi[i[1]] += -1
                else:
                    break

    for i in do_remove:
        if remove_amount == 0:
            break
        corrected_dict[i[0]][i[1]].pop(i[2], None)
        remove_amount -= 1
        if len(corrected_dict[i[0]][i[1]]) == 0:
            corrected_dict[i[0]].pop(i[1],None)
    return corrected_dict, dict_poi