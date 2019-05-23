from collections import defaultdict
import just_discover.DataProcessor as dp
from typing import Dict
import numpy as np
from recordclass import recordclass
import datetime
from functools import reduce
from math import sqrt
import operator
import dill
import copy
from joblib import Parallel, delayed
import matplotlib.pyplot as plt


np.random.seed(seed=8)
np.seterr(all='raise')
latent_factor_values = recordclass('latent_factor_values', 'value delta')
confusion_matrix_row = recordclass('confusion_matrix_row', 'rating true_positive false_positive true_negative false_negative precision recall accuracy')


def __train_eval_parallel_worker(recommender):
    recommender.build_ICAMF(evaluate_while_training=True)
    measurement = recommender.evaluate()
    return measurement



def train_eval_parallel(k_fold, regularizer, learning_rate, num_factors, iterations, clipping, min_num_ratings=1, read_from_file=False):
    if read_from_file:
        rating_obj = dp.read_data_binary_file()
    else:
        rating_obj = dp.read_data_binary(min_num_ratings)

    rating_obj.split_data(k_folds=k_fold)
    recommender_list = list()

    for fold in range(k_fold):
        train_sparse_matrix, test_sparse_matrix = rating_obj.get_kth_fold(fold+1)
        icamf = ICAMF(train_sparse_matrix, test_sparse_matrix, rating_obj, fold=fold+1, regularizer=regularizer,
                      learning_rate=learning_rate, num_factors=num_factors, iterations=iterations, soft_clipping=clipping)
        recommender_list.append(icamf)
    rating_obj.post_process_memory_for_training()
    measurement_results = Parallel(max_nbytes='6G', backend='multiprocessing', n_jobs=k_fold, verbose=1)(map(delayed(__train_eval_parallel_worker), recommender_list))

    print("Kfold training complete \n")
    print("Calculating measurements... \n")
    for result in measurement_results:
        with open(f'Evaluations\\results_fold_{result.fold}_config_{result.configuration}.txt', "w+") as file:
            file.write(str(result))
    summary = reduce(operator.add, measurement_results)

    fig, axs = plt.subplots(2)

    axs[0].plot(summary.loss_list)
    axs[0].set_xlim([0, iterations])
    axs[0].set_ylim([0, max(summary.loss_list)+1000])
    axs[0].set_title('Loss')
    axs[0].set_xlabel('Iterations')
    axs[0].set_ylabel('Loss')

    axs[1].plot(summary.test_accuracy_list, 'tab:orange')
    axs[1].plot(summary.train_accuracy_list, 'tab:green')
    axs[1].set_xlim([0, iterations])
    axs[1].set_ylim([0, 1])
    axs[1].set_title('Test(Orange), Train(Green) Accuracy')
    axs[1].set_xlabel('Iterations')
    axs[1].set_ylabel('Accuracy')

    plt.show()

    with open(f'Evaluations\\results_fold_{summary.fold}_config_{summary.configuration}.txt', "w+") as file:
        file.write(str(summary))
    print(summary)

def train_and_save_model(regularizer, learning_rate, num_factors, iterations, clipping, min_num_ratings=1, read_from_file=False):
    if read_from_file:
        rating_obj = dp.read_data_binary_file()
    else:
        rating_obj = dp.read_data_binary(min_num_ratings)

    rating_obj.rate_matrix = rating_obj.rate_matrix.tocsc()
    icamf = ICAMF(rating_obj.rate_matrix, None, rating_obj, fold="Final_Model", regularizer=regularizer,
                  learning_rate=learning_rate, num_factors=num_factors, iterations=iterations, soft_clipping=clipping)
    icamf.build_ICAMF()
    rating_obj.post_process_memory_for_saving()
    icamf.post_process_memory_for_saving()
    with open(f'{icamf.configuration}.pkl', "wb") as recommender_file:
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

    def __init__(self, train_matrix, test_matrix, rating_obj, fold, regularizer, learning_rate, num_factors, iterations, soft_clipping=False):
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
        self.soft_clipping = soft_clipping
        self.user_bias = np.random.uniform(low=self.init_mean, high=self.init_std, size=self.num_users)
        self.item_bias = np.random.uniform(low=self.init_mean, high=self.init_std, size=self.num_items)

        self.user_factor_matrix = np.random.uniform(self.init_mean, high=self.init_std,
                                                    size=(self.num_users, self.num_factors))
        self.item_factor_matrix = np.random.uniform(self.init_mean, high=self.init_std,
                                                    size=(self.num_items, self.num_factors))

        self.context_factor_matrix = np.random.uniform(self.init_mean, high=self.init_std,
                                                       size=(len(self.rating_object.ids_cond), self.num_factors))
        self.loss_list = list()
        self.test_accuracy_list = list()
        self.test_precision_list = list()
        self.test_recall_list = list()
        self.train_accuracy_list = list()
        self.train_precision_list = list()
        self.train_recall_list = list()
        self.configuration = f'Lrate_{self.learning_rate} regularizer_{self.regularizer_1} latent_factors_{self.num_factors} clipping_{str(self.soft_clipping)}'


    def build_ICAMF(self, evaluate_while_training=False):
        print("Training started: " + f'fold: {str(self.fold)} ' + str(datetime.datetime.now().time()))

        for iteration in range(0, self.iterations):

            loss = 0
            for idx_ctx in range(0, self.train_matrix._shape[1]):
                column = self.train_matrix.getcol(idx_ctx)
                for idx_inner in range(0, column.nnz):

                    user_item_id = column.indices[idx_inner]
                    user_id = self.rating_object.get_user_id_from_user_item_id(user_item_id)
                    item_id = self.rating_object.get_item_id_from_user_item_id(user_item_id)
                    context = idx_ctx
                    conditions = self.rating_object.ids_ctx_list.get(context)
                    rating_user_item_context = column.data[idx_inner]
                    prediction = self.predict(user_id, item_id, context)
                    error_user_item = rating_user_item_context - prediction

                    user_factor_gradients = list()
                    item_factor_gradients = list()
                    context_condition_factor_gradients = [list() for condition in conditions]

                    loss += abs(error_user_item)
                    #loss += error_user_item*error_user_item

                    #Calculate loss
                    loss += 0.5 * self.regularizer_1 * self.item_bias[item_id]*self.item_bias[item_id]
                    loss += 0.5 * self.regularizer_1 * self.user_bias[user_id]*self.user_bias[user_id]
                    loss += 0.5 * self.regularizer_1 * (np.linalg.norm(self.user_factor_matrix[user_id]) ** 2)
                    loss += 0.5 * self.regularizer_1 * (np.linalg.norm(self.item_factor_matrix[item_id]) ** 2)

                    for condition in conditions:
                        try:
                            loss += 0.5 * self.regularizer_1 * (np.linalg.norm(self.context_factor_matrix[condition]) ** 2)
                        except FloatingPointError:
                            loss += 0
                    #Calculate gradients
                    user_bias_gradient = error_user_item - (self.regularizer_1 * self.user_bias[user_id])
                    item_bias_gradient = error_user_item - (self.regularizer_1 * self.item_bias[item_id])

                    for factor in range(0, self.num_factors):
                        user_latent_factor = self.user_factor_matrix[user_id][factor]
                        item_latent_factor = self.item_factor_matrix[item_id][factor]

                        latent_values_list = list()

                        user_values = latent_factor_values(value=user_latent_factor, delta=-(self.regularizer_1 * user_latent_factor))
                        item_values = latent_factor_values(value=item_latent_factor, delta=-(self.regularizer_1 * item_latent_factor))
                        latent_values_list.append(user_values)
                        latent_values_list.append(item_values)

                        for condition in conditions:
                            condition_values = latent_factor_values(value=self.context_factor_matrix[condition][factor], delta=-(self.context_factor_matrix[condition][factor]*self.regularizer_1))
                            latent_values_list.append(condition_values)

                        for idx, tuple_element in enumerate(latent_values_list):
                            for inner_idx, inner_element in enumerate(latent_values_list):
                                if idx != inner_idx:
                                    tuple_element.delta += error_user_item * inner_element.value
                            if idx == 0:
                                user_factor_gradients.append(tuple_element.delta)
                            elif idx == 1:
                                item_factor_gradients.append(tuple_element.delta)
                            else:
                                context_condition_factor_gradients[idx-2].append(tuple_element.delta)
                    factor = 1

                    if self.soft_clipping is not False:
                        gradient_sum_squared = 0
                        try:
                            gradient_sum_squared += item_bias_gradient * item_bias_gradient + user_bias_gradient * user_bias_gradient + sum(
                                x * x for x in user_factor_gradients) + sum(x * x for x in item_factor_gradients)

                            for condition_factor_gradients in context_condition_factor_gradients:
                                gradient_sum_squared += sum(x * x for x in condition_factor_gradients)
                            norm = sqrt(gradient_sum_squared)
                        except FloatingPointError:
                            norm = self.soft_clipping*self.soft_clipping
                        if norm > self.soft_clipping:
                            factor = self.soft_clipping / norm

                    # Update gradients:  First biases, then user_matrix, item_matrix, and contaxt_matrix

                    self.user_bias[user_id] += self.learning_rate * user_bias_gradient * factor
                    self.item_bias[item_id] += self.learning_rate * item_bias_gradient * factor

                    for factor_index, gradient in enumerate(user_factor_gradients):
                        self.user_factor_matrix[user_id][factor_index] += self.learning_rate * gradient * factor
                    for factor_index, gradient in enumerate(item_factor_gradients):
                        self.item_factor_matrix[item_id][factor_index] += self.learning_rate * gradient * factor

                    for idx, condition in enumerate(conditions):
                        for factor_index, gradient in enumerate(context_condition_factor_gradients[idx]):
                            self.context_factor_matrix[condition][
                                factor_index] += self.learning_rate * gradient*factor
            if evaluate_while_training:
                self.evaluate_test_and_train()

            print(f'Fold: {str(self.fold)} ' + "Iteration: " + str(iteration) + "\t" + str(datetime.datetime.now().time()))
            print("Loss: " + str(loss))
            self.loss_list.append(loss)


    def evaluate_test_and_train(self):
        measurement_training = self.evaluate(test_is_training=True)
        self.train_accuracy_list.append(measurement_training.accuracy)
        self.train_precision_list.append(measurement_training.precision)
        self.train_recall_list.append(measurement_training.recall)
        measurement_test = self.evaluate()
        self.test_accuracy_list.append(measurement_test.accuracy)
        self.test_precision_list.append(measurement_test.precision)
        self.test_recall_list.append(measurement_test.recall)


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

    def post_process_memory_for_saving(self):
        self.test_matrix = None
        self.train_matrix = None

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

    def evaluate(self, test_is_training=False):
        if test_is_training:
            test_matrix = self.train_matrix
        else:
            test_matrix = self.test_matrix
        mae = 0
        mse = 0
        ratings = 0

        labeled_as_dict = defaultdict(dict)
        for outer_rating in self.rating_object.rating_values:
            for inner_rating in self.rating_object.rating_values:
                labeled_as_dict[float(outer_rating)][float(inner_rating)] = 0

        confusion_matrix = dict()
        for rating in self.rating_object.rating_values:
            confusion_matrix[rating] = confusion_matrix_row(rating, 0, 0, 0, 0, 0, 0, 0)

        for idx_ctx in range(0, test_matrix._shape[1]):
            column = test_matrix.getcol(idx_ctx)
            for idx_inner in range(0, column.nnz):
                user_item_id = column.indices[idx_inner]
                user_id = self.rating_object.get_user_id_from_user_item_id(user_item_id)
                item_id = self.rating_object.get_item_id_from_user_item_id(user_item_id)
                context = idx_ctx
                rating_user_item_context = column.data[idx_inner]
                prediction = self.predict(user_id, item_id, context)
                error_user_item = rating_user_item_context - prediction
                mae += abs(error_user_item)
                mse += error_user_item*error_user_item
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
                entry.recall = entry.true_positive / (entry.true_positive + entry.false_negative)
            if (entry.true_positive + entry.true_negative + entry.false_positive + entry.false_negative) > 0:
                entry.accuracy = (entry.true_positive + entry.true_negative) / (entry.true_positive + entry.true_negative + entry.false_positive + entry.false_negative)
        precision = 0
        accuracy = 0
        recall = 0
        for entry in confusion_matrix.values():
            precision += entry.precision
            accuracy += entry.accuracy
            recall += entry.recall
        size_confusion_matrix = len(confusion_matrix)
        precision = precision / size_confusion_matrix
        recall = recall / size_confusion_matrix
        accuracy = accuracy / size_confusion_matrix

        mae = mae/ratings
        mse = mse/ratings

        measurement = Measurement(recommender=self, confusion_matrix=confusion_matrix, labeled_as_dict=labeled_as_dict, mae=mae, mse=mse, accuracy=accuracy, precision=precision, recall=recall)
        return measurement


class Measurement:

    def __init__(self, recommender, confusion_matrix:Dict[int, confusion_matrix_row], labeled_as_dict, mae, mse, accuracy, precision, recall):
        self.confusion_matrix = confusion_matrix
        self.labeled_as_dict = labeled_as_dict
        self.configuration = recommender.configuration
        self.mae = mae
        self.mse = mse
        self.fold = recommender.fold
        self.loss_list = recommender.loss_list
        self.test_accuracy_list = recommender.test_accuracy_list
        self.test_precision_list = recommender.test_precision_list
        self.test_recall_list = recommender.test_recall_list
        self.train_accuracy_list = recommender.train_accuracy_list
        self.train_precision_list = recommender.train_precision_list
        self.train_recall_list = recommender.train_recall_list
        self.precision = precision
        self.accuracy = accuracy
        self.recall = recall

    def __add__(self, other_measurement):
        copy_self = copy.deepcopy(self)
        copy_self.fold = str(copy_self.fold) + " & " + str(other_measurement.fold)
        for key, val in other_measurement.confusion_matrix.items():

            copy_self.confusion_matrix[key].true_positive = (copy_self.confusion_matrix[key].true_positive + val.true_positive)
            copy_self.confusion_matrix[key].true_negative = (copy_self.confusion_matrix[key].true_negative + val.true_negative)
            copy_self.confusion_matrix[key].false_positive = (copy_self.confusion_matrix[key].false_positive + val.false_positive)
            copy_self.confusion_matrix[key].false_negative = (copy_self.confusion_matrix[key].false_negative + val.false_negative)
            copy_self.confusion_matrix[key].precision = (copy_self.confusion_matrix[key].precision + val.precision)/2
            copy_self.confusion_matrix[key].recall = (copy_self.confusion_matrix[key].recall + val.recall)/2
            copy_self.confusion_matrix[key].accuracy = (copy_self.confusion_matrix[key].accuracy + val.accuracy)/2

        for outer_key in other_measurement.labeled_as_dict.keys():
            for inner_key, val in other_measurement.labeled_as_dict[outer_key].items():
                copy_self.labeled_as_dict[outer_key][inner_key] += val

        copy_self.precision = (copy_self.precision + other_measurement.precision)/2
        copy_self.recall = (copy_self.recall + other_measurement.recall)/2
        copy_self.accuracy = (copy_self.accuracy + other_measurement.accuracy)/2
        copy_self.mae = (copy_self.mae + other_measurement.mae)/2
        copy_self.mse = (copy_self.mse + other_measurement.mse)/2
        copy_self.loss_list = [(x + y)/2 for x, y in zip(self.loss_list, other_measurement.loss_list)]

        copy_self.accuracy_list = [(x + y) / 2 for x, y in zip(self.test_accuracy_list, other_measurement.test_accuracy_list)]
        copy_self.precision_list = [(x + y) / 2 for x, y in zip(self.test_precision_list, other_measurement.test_precision_list)]
        copy_self.recall_list = [(x + y) / 2 for x, y in zip(self.test_recall_list, other_measurement.test_recall_list)]

        copy_self.train_accuracy_list = [(x + y) / 2 for x, y in zip(self.train_accuracy_list, other_measurement.train_accuracy_list)]
        copy_self.train_precision_list = [(x + y) / 2 for x, y in zip(self.train_precision_list, other_measurement.train_precision_list)]
        copy_self.train_recall_list = [(x + y) / 2 for x, y in zip(self.train_recall_list, other_measurement.train_recall_list)]
        return copy_self

    def __str__(self):
        result = []
        conf = f'Configurations: {self.configuration}'.center(60, '*') + '\n'
        losses = f'Loss for each iteration: {str(self.loss_list)}\n'
        accuracies = f'Accuracy_test for each iteration: {str(self.test_accuracy_list)}\n'
        precisions = f'Precision_test for each iteration: {str(self.test_precision_list)}\n'
        recalls = f'Recall_test for each iteration: {str(self.test_recall_list)}\n'
        accuracies_train = f'Accuracy_training for each iteration: {str(self.train_accuracy_list)}\n'
        precisions_train = f'Precision_training for each iteration: {str(self.train_precision_list)}\n'
        recalls_train = f'Recall_training for each iteration: {str(self.train_recall_list)}\n'
        result.append(conf)
        result.append(losses)
        result.append(accuracies)
        result.append(precisions)
        result.append(recalls)
        result.append(accuracies_train)
        result.append(precisions_train)
        result.append(recalls_train)
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

        over_all_stats = ['\n','Total summary'.center(60,'*'),'\n\n' ,'Precision:'.ljust(14) + f'{round(self.precision,6)} \n', 'Recall:'.ljust(14) + f'{round(self.recall,6)} \n', 'Accuracy:'.ljust(14) + f'{round(self.accuracy,6)} \n', 'MAE:'.ljust(14) + f'{round(self.mae,6)} \n',  'MSE:'.ljust(14) + f'{round(self.mse,6)} \n']
        result.extend(over_all_stats)
        return "".join(result)
