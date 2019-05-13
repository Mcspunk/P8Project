from collections import defaultdict
import just_discover.DataProcessor as dp
from typing import Dict
import numpy as np
from recordclass import recordclass
import datetime
from multiprocessing import Process, Queue
from functools import reduce
import operator
import dill
import copy


np.random.seed(seed=8)
latent_factor_values = recordclass('latent_factor_values', 'index value delta')
confusion_matrix_row = recordclass('confusion_matrix_row', 'rating true_positive false_positive true_negative false_negative precision recall accuracy')
measurement_queue = Queue()


def __train_eval_parallel_worker(recommender, output):
    recommender.build_ICAMF()
    measurement = recommender.evaluate()
    output.put(measurement)


def train_eval_parallel(k_fold, regularizer, learning_rate, num_factors, iterations):
    rating_obj = dp.read_data_binary()
    rating_obj.split_data(k_folds=k_fold)
    recommender_list = list()

    processes = []
    for fold in range(k_fold):
        train_sparse_matrix, test_sparse_matrix = rating_obj.get_kth_fold(fold+1)
        icamf = ICAMF(train_sparse_matrix, test_sparse_matrix, rating_obj, fold=fold+1, regularizer=regularizer,
                      learning_rate=learning_rate, num_factors=num_factors, iterations=iterations)
        recommender_list.append(icamf)

    for recommender in recommender_list:
        p = Process(target=__train_eval_parallel_worker, args=(recommender, measurement_queue))
        processes.append(p)
        p.start()

    for process in processes:
        process.join()

    measurement_results = [measurement_queue.get(p) for p in processes]
    for result in measurement_results:
        with open(f'Evaluations\\results_fold_{result.fold}_config_{result.configuration}.txt', "w+") as file:
            file.write(str(result))
    summary = reduce(operator.add, measurement_results)
    with open(f'Evaluations\\results_fold_{summary.fold}_config_{summary.configuration}.txt', "w+") as file:
        file.write(str(summary))
    print(summary)


def train_and_save_model(regularizer, learning_rate, num_factors, iterations):
    rating_obj = dp.read_data_binary()
    icamf = ICAMF(rating_obj.rate_matrix, None, rating_obj, fold="Final_Model", regularizer=regularizer,
                  learning_rate=learning_rate, num_factors=num_factors, iterations=iterations)
    icamf.build_ICAMF()

    with open(f'{icamf.get_config()}.pkl', "wb") as recommender_file:
        dill.dump(icamf, recommender_file)


class ICAMF:

    learning_rate = 0.03
    regularizer_1 = 0.01
    iterations = 20
    num_users = 0
    num_items = 0
    init_mean = 0.0
    init_std = 0.1
    num_factors = 10

    def __init__(self, train_matrix, test_matrix, rating_obj, fold, regularizer, learning_rate, num_factors, iterations):
        self.train_matrix = train_matrix
        self.global_mean_rating = np.mean(self.train_matrix.data)
        self.test_matrix = test_matrix
        self.fold = fold
        self.regularizer_1 = regularizer
        self.iterations = iterations
        self.num_factors = num_factors
        self.learning_rate = learning_rate
        self.rating_object = rating_obj
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

    def build_ICAMF(self):
        print("Training started: " + f'fold: {str(self.fold)} ' + str(datetime.datetime.now().time()))
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
            print(f'Fold: {str(self.fold)} ' + "Iteration: " + str(iteration) + "\t" + str(datetime.datetime.now().time()))
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
        ctx = self. rating_object.context_str_ids[context]

        for item in item_list:
            item_id = self.rating_object.items_ids[item]
            prediction = self.predict(user_id, item_id, ctx)
            if prediction >= threshold:
                item_ranking_list.append((item, prediction))
        if len(item_ranking_list) > 0:
            item_ranking_list.sort(key=lambda tup: tup[1], reverse=True)
        return item_ranking_list

    def get_config(self):

        return f'Lrate_{self.learning_rate} regularizer_{self.regularizer_1} latent_factors_{self.num_factors}'

    def evaluate(self):

        mae = 0
        ratings = 0

        labeled_as_dict = defaultdict(dict)
        for outer_rating in self.rating_object.rating_values:
            for inner_rating in self.rating_object.rating_values:
                labeled_as_dict[float(outer_rating)][float(inner_rating)] = 0

        confusion_matrix = dict()
        for rating in self.rating_object.rating_values:
            confusion_matrix[rating] = confusion_matrix_row(rating, 0, 0, 0, 0, 0, 0, 0)

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

                closest_rating = min(confusion_matrix.keys(), key=lambda x:abs(x-prediction))

                labeled_as_dict[float(rating_user_item_context)][float(closest_rating)] += 1

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

        for entry in confusion_matrix.values():
            if (entry.true_positive+entry.false_positive) > 0:
                entry.precision = entry.true_positive / (entry.true_positive+entry.false_positive)
            if (entry.true_positive + entry.true_negative) > 0:
                entry.recall = entry.true_positive / (entry.true_positive + entry.true_negative)
            if (entry.true_positive + entry.true_negative + entry.false_positive + entry.false_negative) > 0:
                entry.accuracy = (entry.true_positive + entry.true_negative) / (entry.true_positive + entry.true_negative + entry.false_positive + entry.false_negative)

        mae = mae/ratings

        measurement = Measurement(confusion_matrix, labeled_as_dict, mae, self.fold, self.get_config())
        return measurement


class Measurement:

    def __init__(self, confusion_matrix:Dict[int, confusion_matrix_row], labeled_as_dict, mae, fold, configuration):
        self.confusion_matrix = confusion_matrix
        self.labeled_as_dict = labeled_as_dict
        self.configuration = configuration
        self.mae = mae
        self.fold = fold

        precision = 0
        accuracy = 0
        recall = 0
        for entry in confusion_matrix.values():
            precision += entry.precision
            accuracy += entry.accuracy
            recall += entry.recall
        size_confusion_matrix = len(confusion_matrix)
        self.precision = precision/size_confusion_matrix
        self.recall = recall / size_confusion_matrix
        self.accuracy = accuracy / size_confusion_matrix

    def __add__(self, other_measurement):
        copy_self = copy.deepcopy(self)
        copy_self.fold = str(copy_self.fold) + " & " + str(other_measurement.fold)
        for key, val in other_measurement.confusion_matrix.items():

            copy_self.confusion_matrix[key].true_positive = (copy_self.confusion_matrix[key].true_positive + val.true_positive)
            copy_self.confusion_matrix[key].precision = (copy_self.confusion_matrix[key].true_negative + val.true_negative)
            copy_self.confusion_matrix[key].precision = (copy_self.confusion_matrix[key].false_positive + val.false_positive)
            copy_self.confusion_matrix[key].precision = (copy_self.confusion_matrix[key].false_negative + val.false_negative)
            copy_self.confusion_matrix[key].precision = (copy_self.confusion_matrix[key].precision + val.precision)/2
            copy_self.confusion_matrix[key].precision = (copy_self.confusion_matrix[key].recall + val.recall)/2
            copy_self.confusion_matrix[key].precision = (copy_self.confusion_matrix[key].accuracy + val.recall)/2

        for outer_key in other_measurement.labeled_as_dict.keys():
            for inner_key, val in other_measurement.labeled_as_dict[outer_key].items():
                copy_self.labeled_as_dict[outer_key][inner_key] += val

        copy_self.precision = (copy_self.precision + other_measurement.precision)/2
        copy_self.recall = (copy_self.recall + other_measurement.recall)/2
        copy_self.accuracy = (copy_self.accuracy + other_measurement.accuracy)/2
        copy_self.mae = (copy_self.mae + other_measurement.mae)/2

        return copy_self

    def __str__(self):
        result = []
        conf = f'Configurations: {self.configuration}'.center(60, '*') + '\n'
        result.append(conf)
        headline = '\n' + f'Measumerements of k_fold: {self.fold}'.center(60, '*') + '\n'
        result.append(headline)
        labels = sorted(list(self.labeled_as_dict.keys()))
        ratings_rated_as = [f'The ratings {labels} were rated(row rated as column): \n'.center(20, '*')]
        header = [''.ljust(10)]
        for label in labels:
            header.append(f'{str(label).ljust(10)}')
        header.append('\n')
        ratings_rated_as.extend(header)

        for label in labels:
            ratings_rated_as.append(f'{label}'.ljust(10))
            for inner_label in labels:
                ratings_rated_as.append(f'{self.labeled_as_dict[label][inner_label]}'.ljust(10))
            ratings_rated_as.append('\n')
        result.extend(ratings_rated_as)
        confusion_matrix_str_list = ['\n','Confusion matrix'.center(60, '*') + '\n']
        conf_header = ['Rating'.ljust(10),'TP'.ljust(10),'TN'.ljust(10),'FP'.ljust(10),'FN'.ljust(10),'Precision'.ljust(14),'Recall'.ljust(14),'Accuracy'.ljust(14),'\n']
        confusion_matrix_str_list.extend(conf_header)
        for key, val in self.confusion_matrix.items():
            val: confusion_matrix_row
            confusion_matrix_str_list.append(f'{str(float(key)).ljust(10)}{str(val.true_positive).ljust(10)}{str(val.true_negative).ljust(10)}{str(val.false_positive).ljust(10)}{str(val.false_negative).ljust(10)}{str(round(val.precision,6)).ljust(14)}{str(round(val.recall,6)).ljust(14)}{str(round(val.accuracy,6)).ljust(14)} \n')

        result.extend(confusion_matrix_str_list)

        over_all_stats = ['\n','Total summary'.center(60,'*'),'\n\n' ,'Precision:'.ljust(14) + f'{round(self.precision,6)} \n', 'Recall:'.ljust(14) + f'{round(self.recall,6)} \n', 'Accuracy:'.ljust(14) + f'{round(self.accuracy,6)} \n', 'MAE:'.ljust(14) + f'{round(self.mae,6)} \n']
        result.extend(over_all_stats)
        return "".join(result)
