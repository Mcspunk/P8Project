import scipy.sparse
import scipy
from collections import defaultdict
from just_discover.DataProcessor import RatingObj
import numpy as np
import math
import random
import datetime
from multiprocessing.dummy import Pool as ThreadPool

class SLM_Recommender:

    iterations = 100
    rating_object: RatingObj
    train_matrix: scipy.sparse.csr_matrix
    test_matrix: scipy.sparse.csr_matrix
    train_traditional: scipy.sparse.csr_matrix
    num_users: int
    num_items: int
    fold: int
    context_vector = 0
    all_items = list()
    item_nns = defaultdict()
    knn = 0
    w = 0
    reg_lw1 = 0.0001
    reg_lw2 = 0.0001
    reg_c = 0.001
    learning_rate = 0.001


    #reg_lw1 = 0.0001
    #reg_lw2 = 0.0001
    #reg_c = 0.001
    #learning_rate = 0.02



    lower_bound = 0
    upper_bound = 0

    def __init__(self, train_matrix: scipy.sparse.csr_matrix, test_matrix: scipy.sparse.csr_matrix, traditional_rating,  fold:int, rating_obj: RatingObj, knn):
        self.train_matrix = train_matrix
        self.test_matrix = test_matrix
        self.train_traditional = traditional_rating
        self.fold = fold
        self.rating_object = rating_obj
        self.num_users = self.rating_object.users
        self.num_items = self.rating_object.items
        self.knn = knn

    def init_model(self):

        self.upper_bound = 1 / math.sqrt(3)
        self.lower_bound = 1 / math.pow(10, 100)
        #self.upper_bound = 1.0/math.sqrt(len(self.rating_object.dim_ids))
        #self.lower_bound = 1.0/math.pow(10, 100)
        self.context_vector = np.random.uniform(low=0.0, high=self.upper_bound, size=(len(self.rating_object.cond_dim_dict),))
        self.w = np.random.uniform(low=0.0, high=1.0, size=(self.num_items, self.num_items))
        np.fill_diagonal(self.w, 0)
        self.all_items = set(self.train_traditional.indices)

        #if self.knn > 0:
        #   for item in range(self.num_items):


    def build_model(self):

        file = open("C://Users//Lasse//Desktop//Logs", "w+")
        try:
            for iteration in range(self.iterations):
                print(str(iteration) + ":Iteration :: " + str(datetime.datetime.now().time()))
                loss = 0
                for idx, matrix_entry in enumerate(self.train_matrix):
                    if matrix_entry.nnz is 0:
                        continue
                    for inner_value in range(0, matrix_entry.nnz):
                        if matrix_entry.nnz is 0:
                            continue
                        user_item_id = idx
                        user_id = self.rating_object.get_user_id_from_user_item_id(user_item_id)
                        item_id = self.rating_object.get_item_id_from_user_item_id(user_item_id)
                        rating_user_item_context = matrix_entry.data[inner_value]
                        context = matrix_entry.indices[inner_value]

                        conditions = self.rating_object.ids_ctx_list.get(context)
                        tree = lambda: defaultdict(tree)
                        to_be_updated_sim_factor = tree()
                        to_be_updated_w_factor = tree()

                        #to_be_updated_sim_factor = defaultdict(lambda: defaultdict(dict))
                        #to_be_updated_w_factor = defaultdict(lambda: defaultdict(dict))


                        if self.knn > 0:
                            nns = self.item_nns.get(user_id)
                        else:
                            nns = self.all_items

                        ru = self.train_traditional.getrow(user_id)
                        prediction = 0

                        for k in nns:
                            if k in ru.indices:
                                if k != item_id:
                                    key = str(user_id) + "," + str(k)
                                    uiid = self.rating_object.ui_ids.get(key)
                                    if type(uiid) is not int:
                                        print("stop")
                                    ctx_id = self.train_matrix.getrow(uiid).indices
                                    index = random.randint(0, len(ctx_id)-1)
                                    ctx = ctx_id[index]

                                    conditions_from = self.rating_object.ids_ctx_list.get(ctx)

                                    ruk = self.train_matrix.getrow(uiid).getcol(ctx).data[0]
                                    rating = ruk * self.w[k][item_id]

                                    dist = 0
                                    for cdx, condition in enumerate(conditions):
                                        condition2 = conditions_from[cdx]
                                        pos1 = self.context_vector[condition]
                                        pos2 = self.context_vector[condition2]
                                        diff = pos1-pos2
                                        dist += math.pow(diff, 2)
                                        if condition != condition2:
                                            update = rating * diff
                                            if condition in to_be_updated_sim_factor and condition2 in to_be_updated_sim_factor[condition]:
                                                update += to_be_updated_sim_factor[condition][condition2]
                                            to_be_updated_sim_factor[condition][condition2] = update
                                    dist = math.sqrt(dist)
                                    if dist == 0:
                                        dist = self.lower_bound
                                    for outer_key in to_be_updated_sim_factor.keys():
                                        for inner_key in to_be_updated_sim_factor[outer_key]:
                                            #val = to_be_updated_sim_factor[outer_key][inner_key]/dist
                                            val = 12
                                            to_be_updated_sim_factor[outer_key][inner_key] = val
                                            #to_be_updated_sim_factor[outer_key][inner_key] = to_be_updated_sim_factor[outer_key][inner_key]/dist
                                    similarity = 1 - dist
                                    prediction += rating * similarity
                                    val = ruk*similarity
                                    to_be_updated_w_factor[k][item_id] = ruk*similarity

                        #print("All k's done " + str(datetime.datetime.now().time()))
                        error_user_item_context = rating_user_item_context - prediction
                        loss += error_user_item_context * error_user_item_context

                        # update context similarities

                        if len(to_be_updated_sim_factor.keys()) > 0:
                            for outer_key in to_be_updated_sim_factor.keys():
                                #print("sim-factor keys: Outer-key = " + str(outer_key) + " " + str(datetime.datetime.now().time()))
                                for inner_key in to_be_updated_sim_factor[outer_key]:
                                    pos1 = self.context_vector[outer_key]
                                    pos2 = self.context_vector[inner_key]

                                    pos1_update = pos1 + self.learning_rate *((error_user_item_context * to_be_updated_sim_factor[outer_key][inner_key]) - self.reg_c*pos1)
                                    pos2_update = pos2 - self.learning_rate * ((error_user_item_context * to_be_updated_sim_factor[outer_key][inner_key]) + self.reg_c * pos2)

                                    # simple rule to constrain the distance

                                    if pos1_update < 0:
                                        pos1_update = self.lower_bound
                                    elif pos1_update > self.upper_bound:
                                        pos1_update = self.upper_bound - self.lower_bound

                                    if pos2_update < 0:
                                        pos2_update = self.lower_bound
                                    elif pos2_update > self.upper_bound:
                                        pos2_update = self.upper_bound - self.lower_bound

                                    #pos1_update = self.lower_bound if pos1_update < 0 else pos1_update
                                    #pos1_update = self.upper_bound - self.lower_bound if pos1_update > self.upper_bound else pos1_update

                                    #pos2_update = self.lower_bound if pos2_update < 0 else pos2_update
                                    #pos2_update = self.upper_bound - self.lower_bound if pos2_update > self.upper_bound else pos2_update

                                    self.context_vector[inner_key] = pos1_update
                                    self.context_vector[outer_key] = pos2_update

                        # updating w

                        if len(to_be_updated_w_factor.keys()) > 0:
                            #print("Updating W: " + str(datetime.datetime.now().time()))
                            for outer_key in to_be_updated_w_factor.keys():
                                for inner_key in to_be_updated_w_factor[outer_key]:
                                    update = self.w[inner_key][outer_key]
                                    loss += self.reg_lw2*update*update + self.reg_lw1*update
                                    delta_w = error_user_item_context*to_be_updated_w_factor[outer_key][inner_key] - self.reg_lw2*update - self.reg_lw1
                                    update += self.learning_rate * delta_w
                                    self.w[outer_key][inner_key] = update
                file.write("Iteration: " + str(iteration))
                file.write(str(self.w))
                file.write(str(self.context_vector))
        except Exception as e:
            print(e)
        print("done")



    def predict(self, user_id, item, context, location = -1, ):

        if self.knn > 0:
            nns = self.item_nns.get(user_id)
        else:
            nns = self.all_items

        prediction = 0
        ru = self.train_traditional.getrow(user_id)
        conditions = self.rating_object.ids_ctx_list.get(context)

        for k in nns:
            if k != item and k in ru.indices:

                key = str(user_id) + "," + str(k)
                uiid = self.rating_object.ui_ids.get(key)
                ctx_id = self.train_matrix.getrow(uiid).indices
                index = random.randint(0, len(ctx_id) - 1)
                ctx = ctx_id[index]

                conditions_from = self.rating_object.ids_ctx_list.get(ctx)

                ruk = self.train_matrix.getrow(uiid).getcol(ctx).data[0]

                dist = 0
                for cdx, condition in enumerate(conditions):
                    condition2 = conditions_from[cdx]
                    pos1 = self.context_vector[condition]
                    pos2 = self.context_vector[condition2]
                    dist += math.pow((pos1 - pos2), 2)

                dist = math.sqrt(dist)
                sim = 1-dist

                prediction += ruk * self.w[k, item] * sim

        return prediction

    def evaluate(self, path):

        results_file = open(path, "w+")

        tree = lambda: defaultdict(tree)
        user_context_item_train_multimap = self.rating_object.make_user_context_item_multimap(self.train_matrix)
        user_context_item_test_multimap = self.rating_object.make_user_context_item_multimap(self.test_matrix)

        capacity = len(user_context_item_train_multimap.keys())

        candidate_items = self.rating_object.make_item_set_from_sparse_matrix(self.train_matrix)
        candidate_items_count = len(candidate_items)


        for user in user_context_item_test_multimap.keys():
            context_items_test_multimap = user_context_item_test_multimap.get(user)
            context_capacity = len(context_items_test_multimap.keys())

            context_items_train = user_context_item_train_multimap.get(user)

            for ctx in context_items_test_multimap.keys():

                pos_items = context_items_test_multimap.get(ctx)
                correct_items = set()

                #Items that are both in training and test data (can be expanded to only include positive rated items)
                for item in pos_items:
                    if item in candidate_items:
                        correct_items.add(item)

                if len(correct_items) == 0:
                    continue

                rated_items = context_items_train.get(ctx)

                #Predict ranking scores of all candidate items
                item_score_tuple_list = list()
                for item in candidate_items:
                    if item not in rated_items:
                        score = self.predict(user, item, ctx)
                        item_score_tuple_list.append((item, score))
                # If no recommendation avaílable
                if len(item_score_tuple_list) == 0:
                    continue

                item_score_tuple_list.sort(key=lambda tup: tup[1], reverse=True)
                ranked_items = list()
                output_string_list = list()
                for item, score in item_score_tuple_list[0:5]:
                    output_string_list.append(self.rating_object.ids_items.get(item))

                    if item in pos_items:
                        output_string_list.append(item)
                    output_string_list.append(score)

                item_scores_string = ' '.join([str(elem) for elem in output_string_list])
                conditions_in_rating = self.rating_object.ids_ctx_list.get(ctx)
                condition_string = '; '.join([self.rating_object.ids_cond.get(elem) for elem in conditions_in_rating])
                user_string = str(self.rating_object.ids_user.get(user))

                results_file.write(user_string + "\t" + condition_string + "\t" + item_scores_string + "\n")

        results_file.close()







