import scipy.sparse
import scipy.sparse.csr as csr_matrix
import scipy
from collections import defaultdict
import just_discover.DataProcessor as dp
from just_discover.DataProcessor import RatingObj
from typing import Dict
import numpy as np
from recordclass import recordclass
import math
import random
import datetime
import copy
from multiprocessing import Process, Manager
from multiprocessing.managers import BaseManager
from threading import Thread
from multiprocessing import Pool
import pickle


np.random.seed(seed=8)
latent_factor_values = recordclass('Latent_factor_values', 'index value delta')
confusion_matrix_row = recordclass('Confusion_matrix_row', 'rating true_positive false_positive true_negative false_negative precision recall accuracy')


def execute(k_fold, regularizer, learning_rate, num_factors, iterations):
    rating_obj = dp.read_data_binary()
    rating_obj.split_data(k_folds=k_fold)
    train_sparse_matrix, test_sparse_matrix = rating_obj.get_kth_fold(1)
    icamf = ICAMF(train_sparse_matrix, test_sparse_matrix, rating_obj,fold=1,regularizer=regularizer,
                  learning_rate=learning_rate,num_factors=num_factors,iterations=iterations)
    icamf.build_ICAMF()
    measurement = icamf.evaluate()
    pickle.dump(icamf, open("icamf_model.p", "wb"))


class CustomProcess(Process):
    def __init__(self, obj):
        super(CustomProcess, self).__init__()
        self.obj = obj

    def run(self):
        self.obj.build_ICAMF()


class ICAMF:

    learning_rate = 0.03
    regularizer_1 = 0.01
    fold: int
    iterations = 20
    rating_object = RatingObj()

    train_matrix: csr_matrix
    test_matrix: csr_matrix
    num_users = 0
    num_items = 0
    global_mean_rating = 0

    init_mean = 0.0
    init_std = 0.1

    num_factors = 10

    def __init__(self, train_matrix: scipy.sparse.csr_matrix, test_matrix: scipy.sparse.csr_matrix, rating_obj, fold:int, regularizer, learning_rate, num_factors, iterations):
        self.train_matrix = train_matrix
        self.global_mean_rating = np.mean(self.train_matrix.data)
        self.test_matrix = test_matrix
        self.fold = fold
        self.regularizer_1 = regularizer
        self.iterations = iterations
        self.num_factors = num_factors
        self.learning_rate = learning_rate
        self.rating_object = copy.deepcopy(rating_obj)
        self.num_users = self.rating_object.users
        self.num_items = self.rating_object.items

        self.user_bias = np.random.uniform(low=self.init_mean, high=self.init_std, size=self.num_users)
        self.item_bias = np.random.uniform(low=self.init_mean, high=self.init_std, size=self.num_items)

        self.user_factor_matrix = np.random.uniform(self.init_mean, high=self.init_std,
                                                    size=(self.num_users, self.num_factors))
        self.item_factor_matrix = np.random.uniform(self.init_mean, high=self.init_std,
                                                    size=(self.num_items, self.num_factors))

        self.context_factor_matrix = np.random.uniform(self.init_mean, high=self.init_std,
                                                       size=(len(self.rating_object.ids_cond), self.num_factors))

    def init_ICAMF(self):
        print("Init")

    def build_ICAMF(self):
        print("Training started: " + str(datetime.datetime.now().time()))
        for iteration in range(0, self.iterations):

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
                    context = matrix_entry.indices[inner_value]
                    conditions = self.rating_object.ids_ctx_list.get(context)
                    rating_user_item_context = matrix_entry.data[inner_value]
                    prediction = self.predict(user_id, item_id, context)
                    error_user_item = rating_user_item_context - prediction

                    loss += error_user_item * error_user_item

                    user_bias = self.user_bias[user_id]
                    item_bias = self.item_bias[item_id]
                    sgd_user_bias = error_user_item - (self.regularizer_1 * user_bias)
                    sgd_item_bias = error_user_item - (self.regularizer_1 * item_bias)

                    self.user_bias[user_id] += sgd_user_bias * self.learning_rate
                    self.item_bias[item_id] += sgd_item_bias * self.learning_rate

                    loss += self.regularizer_1 * item_bias * item_bias
                    loss += self.regularizer_1 * user_bias * user_bias

                    for factor in range(0, self.num_factors):
                        user_latent_factor = self.user_factor_matrix[user_id][factor]
                        item_latent_factor = self.item_factor_matrix[item_id][factor]
                        latent_values_list = list()

                        user_values = latent_factor_values("user", user_latent_factor, -(self.regularizer_1 * user_latent_factor))
                        item_values = latent_factor_values("item", item_latent_factor, -(self.regularizer_1 * item_latent_factor))
                        latent_values_list.append(user_values)
                        latent_values_list.append(item_values)

                        for condition in conditions:
                            condition_values = latent_factor_values(condition, self.context_factor_matrix[condition][factor], -(self.context_factor_matrix[condition][factor]*self.regularizer_1))
                            latent_values_list.append(condition_values)
                        for tuple_element in latent_values_list:
                            val = 0
                            for inner_element in latent_values_list:
                                if tuple_element.index != inner_element.index:
                                    val += error_user_item * inner_element.value
                            tuple_element.delta += val

                            loss += self.regularizer_1 * tuple_element.value * tuple_element.value

                        self.user_factor_matrix[user_id][factor] += self.learning_rate * latent_values_list[0].delta
                        self.item_factor_matrix[item_id][factor] += self.learning_rate * latent_values_list[1].delta

                        for index, condition in enumerate(conditions):
                            self.context_factor_matrix[condition][factor] += self.learning_rate * latent_values_list[index+2].delta
            loss *= 0.5
            print("Iteration: " + str(iteration) + "\t" + str(datetime.datetime.now().time()))
            print("Loss: " + str(loss))

    def build_ICAMF_fromObj(self, obj):

        print(obj)
        print("Training started: " + str(datetime.datetime.now().time()))
        for iteration in range(0, self.iterations):

            loss = 0

            for idx, matrix_entry in enumerate(self.train_matrix):
                if matrix_entry.nnz is 0:
                    continue
                for inner_value in range(0, matrix_entry.nnz):
                    if matrix_entry.nnz is 0:
                        continue
                    user_item_id = idx
                    user_id = obj.get_user_id_from_user_item_id(user_item_id)
                    item_id = obj.get_item_id_from_user_item_id(user_item_id)
                    context = matrix_entry.indices[inner_value]
                    conditions = obj.ids_ctx_list.get(context)
                    rating_user_item_context = matrix_entry.data[inner_value]
                    prediction = self.predict(user_id, item_id, context)
                    error_user_item = rating_user_item_context - prediction

                    loss += error_user_item * error_user_item

                    user_bias = self.user_bias[user_id]
                    item_bias = self.item_bias[item_id]
                    sgd_user_bias = error_user_item - (self.regularizer_1 * user_bias)
                    sgd_item_bias = error_user_item - (self.regularizer_1 * item_bias)

                    self.user_bias[user_id] += sgd_user_bias * self.learning_rate
                    self.item_bias[item_id] += sgd_item_bias * self.learning_rate

                    loss += self.regularizer_1 * item_bias * item_bias
                    loss += self.regularizer_1 * user_bias * user_bias

                    for factor in range(0, self.num_factors):
                        user_latent_factor = self.user_factor_matrix[user_id][factor]
                        item_latent_factor = self.item_factor_matrix[item_id][factor]
                        latent_values_list = list()

                        user_values = latent_factor_values("user", user_latent_factor,
                                                           -(self.regularizer_1 * user_latent_factor))
                        item_values = latent_factor_values("item", item_latent_factor,
                                                           -(self.regularizer_1 * item_latent_factor))
                        latent_values_list.append(user_values)
                        latent_values_list.append(item_values)

                        for condition in conditions:
                            condition_values = latent_factor_values(condition,
                                                                    self.context_factor_matrix[condition][factor], -(
                                            self.context_factor_matrix[condition][factor] * self.regularizer_1))
                            latent_values_list.append(condition_values)
                        for tuple_element in latent_values_list:
                            val = 0
                            for inner_element in latent_values_list:
                                if tuple_element.index != inner_element.index:
                                    val += error_user_item * inner_element.value
                            tuple_element.delta += val

                            loss += self.regularizer_1 * tuple_element.value * tuple_element.value

                        self.user_factor_matrix[user_id][factor] += self.learning_rate * latent_values_list[0].delta
                        self.item_factor_matrix[item_id][factor] += self.learning_rate * latent_values_list[1].delta

                        for index, condition in enumerate(conditions):
                            self.context_factor_matrix[condition][factor] += self.learning_rate * latent_values_list[
                                index + 2].delta
            loss *= 0.5
            print("Iteration: " + str(iteration) + "\t" + str(datetime.datetime.now().time()))
            print("Loss: " + str(loss))

    def predict(self, user, item, context):

        conditions = self.rating_object.ids_ctx_list.get(context)
        biases = self.global_mean_rating + self.user_bias[user] + self.item_bias[item]
        user_item_product = np.dot(self.user_factor_matrix[user], self.item_factor_matrix[item])
        user_context_product = 0
        item_context_product = 0

        for condition in conditions:
            user_context_product += np.dot(self.user_factor_matrix[user], self.context_factor_matrix[condition])
            item_context_product += np.dot(self.item_factor_matrix[item], self.context_factor_matrix[condition])

        prediction = biases + user_item_product + user_context_product + item_context_product

        return prediction

    def top_recommendations(self, user, item_list, context, threshold):

        item_ranking_list = list()

        user_id = self.rating_object.user_ids[user]
        ctx = self. rating_object.ctx_ids[context]

        for item in item_list:
            item_id = self.rating_object.item_ids[item]
            prediction = self.predict(user_id, item_id, ctx)
            if prediction >= threshold:
                item_ranking_list.append((item, prediction))
        if len(item_ranking_list) > 0:
            item_ranking_list.sort(key=lambda tup: tup[1], reverse=True)
        return item_ranking_list

    def evaluate(self):

        mae = 0
        ratings = 0
        mean = np.mean(list(self.rating_object.rating_values))

        confusion_matrix = dict()
        for rating in self.rating_object.rating_values:
            confusion_matrix[rating] = confusion_matrix_row(rating, 0, 0, 0, 0, 0, 0, 0)

        rating_values_simple = set()
        rating_values_simple.add(min(self.rating_object.rating_values))
        rating_values_simple.add(mean)
        rating_values_simple.add(max(self.rating_object.rating_values))
        confusion_matrix_simple = dict()
        for rating in rating_values_simple:
            confusion_matrix_simple[rating] = confusion_matrix_row(rating, 0, 0, 0, 0, 0, 0, 0)

        for idx, matrix_entry in enumerate(self.test_matrix):
            if matrix_entry.nnz is 0:
                continue
            for inner_value in range(0, matrix_entry.nnz):
                if matrix_entry.nnz is 0:
                    continue
                user_item_id = idx
                user_id = self.rating_object.get_user_id_from_user_item_id(user_item_id)
                item_id = self.rating_object.get_item_id_from_user_item_id(user_item_id)
                context = matrix_entry.indices[inner_value]
                rating_user_item_context = matrix_entry.data[inner_value]
                prediction = self.predict(user_id, item_id, context)
                error_user_item = abs(rating_user_item_context - prediction)
                mae += error_user_item
                ratings += 1

                rating_user_item_context_simple = min(confusion_matrix_simple.keys(), key=lambda x: abs(x - prediction))
                rating_user_item_context_simple_tweak = rating_user_item_context_simple
                if rating_user_item_context_simple < mean:
                    rating_user_item_context_simple_tweak -= 0.0001
                elif rating_user_item_context_simple > mean:
                    rating_user_item_context_simple_tweak += 0.0001

                closest_rating = min(confusion_matrix.keys(), key=lambda x:abs(x-prediction))

                closest_rating_simple = min(confusion_matrix_simple, key=lambda x:abs(x-rating_user_item_context_simple_tweak))

                if closest_rating == rating_user_item_context:
                    for entry in confusion_matrix.values():
                        if entry.rating == closest_rating:
                            entry.true_positive += 1
                        else:
                            entry.true_negative += 1
                else:
                    for entry in confusion_matrix.values():
                        if entry.rating == closest_rating:
                            entry.false_positive += 1
                        elif entry.rating == rating_user_item_context:
                            entry.false_negative += 1
                        else:
                            entry.true_negative += 1

                if closest_rating_simple == rating_user_item_context_simple:
                    for entry in confusion_matrix_simple.values():
                        if entry.rating == closest_rating_simple:
                            entry.true_positive += 1
                        else:
                            entry.true_negative += 1
                else:
                    for entry in confusion_matrix_simple.values():
                        if entry.rating == closest_rating_simple:
                            entry.false_positive += 1
                        elif entry.rating == rating_user_item_context_simple:
                            entry.false_negative += 1
                        else:
                            entry.true_negative += 1

        for entry in confusion_matrix.values():
            entry.precision = entry.true_positive/(entry.true_positive+entry.false_positive)
            entry.recall = entry.true_positive / (entry.true_positive + entry.true_negative)
            entry.accuracy = (entry.true_positive + entry.true_negative) / (entry.true_positive + entry.true_negative + entry.false_positive + entry.false_negative)

        for entry in confusion_matrix_simple.values():
            entry.precision = entry.true_positive / (entry.true_positive + entry.false_positive)
            entry.recall = entry.true_positive / (entry.true_positive + entry.true_negative)
            entry.accuracy = (entry.true_positive + entry.true_negative) / (
                        entry.true_positive + entry.true_negative + entry.false_positive + entry.false_negative)

        mae = mae/ratings

        measurement = Measument(confusion_matrix, confusion_matrix_simple, mae)
        return measurement


class Measument:

    confusion_matrix: Dict[int, confusion_matrix_row]
    confusion_matrix_simple: Dict[int, confusion_matrix_row]

    precision = 0
    accuracy = 0
    recall = 0
    mae = 0

    precision_simple = 0
    accuracy_simple = 0
    recall_simple = 0

    def __init__(self, confusion_matrix:Dict[int, confusion_matrix_row], confusion_matrix_simple:Dict[int, confusion_matrix_row], mae):
        self.confusion_matrix = confusion_matrix
        self.confusion_matrix_simple = confusion_matrix_simple
        self.mae = mae

        precision = 0
        accuracy = 0
        recall = 0
        for entry in confusion_matrix:
            precision += entry.precision
            accuracy += entry.accuracy
            recall += entry.recall
        size_confusion_matrix = len(confusion_matrix)
        self.precision = precision/size_confusion_matrix
        self.recall = recall / size_confusion_matrix
        self.accuracy = accuracy / size_confusion_matrix

        precision = 0
        accuracy = 0
        recall = 0
        for entry in confusion_matrix_simple:
            precision += entry.precision
            accuracy += entry.accuracy
            recall += entry.recall
        size_confusion_matrix_simple = len(confusion_matrix_simple)
        self.precision_simple = precision / size_confusion_matrix_simple
        self.recall_simple = recall / size_confusion_matrix_simple
        self.accuracy_simple = accuracy / size_confusion_matrix_simple
