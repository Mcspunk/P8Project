import numpy as np
import scipy.sparse
from collections import namedtuple
import psycopg2
import creds_psql as creds
from typing import List
from typing import Dict
from collections import defaultdict

np.random.seed(seed=8)
ContextRatingPair = namedtuple("ContextRatingPair", "context rating")
ItemRatingPair = namedtuple("ItemRatingPair", "item rating")

class RatingObj:
    # row:User_Item column:ctx_index, data: rating
    rate_matrix: scipy.sparse.csr_matrix
    #row:User_Item column:ctx_index, data: kth-fold
    assign_matrix: scipy.sparse.csr_matrix
    items: int
    users: int

    user_ids = dict()
    items_ids = dict()
    ctx_ids: Dict[str, int] = dict()
    ui_ids: Dict[str, int] = dict()
    dim_ids: Dict[str, int] = dict()
    cond_ids: Dict[str, int] = dict()

    ids_user: Dict[int, str] = dict()
    ids_items: Dict[int, str] = dict()
    ids_ctx: Dict[int, str] = dict()
    ids_ctx_list: Dict[int, list] = dict()
    ids_ui: Dict[int, str] = dict()
    ids_dim: Dict[int, str] = dict()
    ids_cond: Dict[int, str] = dict()

    num_rating: int
    ui_user_ids: Dict[int, int] = dict()
    ui_item_ids: Dict[int, int] = dict()
    cond_dim_dict: Dict[int, int] = dict()
    dim_cond_dict = defaultdict(set)

    user_rated_multimap = defaultdict(set)
    item_rated_multimap = defaultdict(set)
    user_item_user_ids_multimap = defaultdict(set)
    user_item_item_ids_multimap = defaultdict(set)

    context_condition_multimap = defaultdict(set)
    condition_context_multimap = defaultdict(set)

    rating_values = set()

    user_item_context_rating = dict(list())
    ratings_count = 0

    train: scipy.sparse.csr_matrix

    def __init__(self, obj=None):
        if obj is not None:
            self.assign_matrix = obj.assign_matrix
            self.cond_dim_dict = obj.cond_dim_dict
            self.cond_ids = obj.cond_ids
            self.condition_context_multimap = obj.condition_context_multimap
            self.context_condition_multimap = obj.context_condition_multimap
            self.ctx_ids = obj.ctx_ids
            self.dim_cond_dict = obj.dim_cond_dict
            self.dim_ids = obj.dim_ids
            self.ids_cond = obj.ids_cond
            self.ids_items = obj.ids_items
            self.ids_dim = obj.ids_dim
            self.ids_ui = obj.ids_ui
            self.ids_user = obj.ids_user
            self.item_rated_multimap = obj.item_rated_multimap
            self.items_ids = obj.items_ids
            self.rate_matrix = obj.rate_matrix
            self.ratings = obj.ratings
            self.ui_ids = obj.ui_ids
            self.ui_item_ids = obj.ui_item_ids
            self.ui_user_ids = obj.ui_user_ids
            self.user_ids = obj.user_ids
            self.user_item_context_rating = obj.user_item_context_rating
            self.user_item_item_ids_multimap = obj.user_item_item_ids_multimap
            self.user_item_user_ids_multimap = obj.user_item_user_ids_multimap
            self.user_rated_multimap = obj.user_rated_multimap

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

    def get_user_id_from_user_item_id(self, user_item_id):
        return self.ui_user_ids.get(user_item_id)

    def get_item_id_from_user_item_id(self, user_item_id):
        return self.ui_item_ids.get(user_item_id)

    def get_conditions(self, ctx):
        ctx = 0

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
        tree = lambda: defaultdict(tree)
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

    cursor.execute("SELECT justdiscover.reviews.id, justdiscover.users.id_sk, justdiscover.reviews.poi_id, justdiscover.reviews.rating, justdiscover.reviews.month_visited, justdiscover.reviews.company FROM justdiscover.reviews, justdiscover.users WHERE users.id = reviews.user_id ORDER BY reviews.id LIMIT %s OFFSET %s", (limit, offset))

    ctx_dims: List[str] = [desc[0] for desc in cursor.description[4:]]
    row_number = 0
    while True:
        values = list()
        row = cursor.fetchone()
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
        if row is None:
            break
    conn.commit()
    conn.close()


def read_data_binary():
    rating_obj = RatingObj()
    conn_string = "host=" + creds.PGHOST + " port=" + creds.PORT + " dbname=" + creds.PGDATABASE + " user=" + creds.PGUSER + " password=" + creds.PGPASSWORD

    db = psycopg2.connect(conn_string)
    cursor = db.cursor()
    cursor.execute("SELECT * FROM justdiscover.reviews_binary ORDER BY  id ASC LIMIT 80000")

    colnames: List[str] = [desc[0] for desc in cursor.description[4:]]
    counter = 0
    for context in colnames:
        context_split = context.strip().split(":")
        context_dim = context_split[0]
        dimc = rating_obj.dim_ids.get(context_dim, rating_obj.dim_ids.keys().__len__())
        rating_obj.dim_ids[context_dim] = dimc
        rating_obj.cond_ids[context] = counter
        rating_obj.dim_cond_dict[dimc].add(counter)
        rating_obj.cond_dim_dict[counter] = dimc
        counter += 1

    while True:
        row = cursor.fetchone()
        if row is None:
            break
        user = row[1]
        row_id = rating_obj.user_ids.get(user, len(rating_obj.user_ids))
        rating_obj.user_ids[user] = row_id

        item = row[2]
        col_id = rating_obj.items_ids.get(item, len(rating_obj.items_ids))
        rating_obj.items_ids[item] = col_id

        rating = row[3]
        rating_obj.rating_values.add(rating)
        rating_obj.ratings_count += 1
        user_item = str(row_id) + "," + str(col_id)
        user_item_id = rating_obj.ui_ids.get(user_item, len(rating_obj.ui_ids))
        rating_obj.ui_ids[user_item] = user_item_id

        rating_obj.user_rated_multimap[row_id].add(user_item_id)
        rating_obj.item_rated_multimap[col_id].add(user_item_id)

        rating_obj.ui_user_ids[user_item_id] = row_id
        rating_obj.ui_item_ids[user_item_id] = col_id

        rating_obj.user_item_user_ids_multimap[user_item_id].add(row_id)
        rating_obj.user_item_item_ids_multimap[user_item_id].add(col_id)

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

    for key, val in rating_obj.ids_ctx.items():
        rating_obj.ids_ctx_list[key] = [int(s) for s in val.split(',')]

    rating_obj.ids_user = dict((v, k) for k, v in rating_obj.user_ids.items())
    rating_obj.ids_items = dict((v, k) for k, v in rating_obj.items_ids.items())
    rating_obj.ids_cond = dict((v, k) for k, v in rating_obj.cond_ids.items())
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

    for idx, user_item_row in enumerate(rating_obj.user_item_context_rating.items()):
        end_ptr += len(user_item_row[1])
        row_ptr_np_array[idx + 1] = end_ptr
        for ctx_rate_pair in user_item_row[1]:
            row_data_np_array[element_index] = ctx_rate_pair.rating
            column_id_np_array[element_index] = ctx_rate_pair.context
            element_index += 1

    rating_obj.items = len(rating_obj.items_ids)
    rating_obj.users = len(rating_obj.user_ids)

    rate_matrix = scipy.sparse.csr_matrix((row_data_np_array, column_id_np_array, row_ptr_np_array),
                                          shape=(number_of_rows, number_of_columns))
    rating_obj.rate_matrix = rate_matrix

    return rating_obj
