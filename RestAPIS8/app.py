from flask import Flask, make_response
import json
from flask_cors import CORS
from flask import request, Response
import psycopg2 as psy
import datetime
import just_discover.Recommender as recommender
import just_discover.DataProcessor as dataprocessor
import requests
import pickle
import dill
import copy

host = "jd-database.ccwvupidct47.eu-west-3.rds.amazonaws.com"
database = "jd_database"
user = "palminde"
password = "sw_809_p8"

app = Flask(__name__)
cors = CORS(app, support_credentials=True, resources={r"/api/*": {"origins": "*", "support_credentials": True}})

icamf_recommender: recommender.ICAMF

@app.route('/api/get-preferences/', methods=['POST'])
def get_preferences():
    json_date = request.get_json(force=True)
    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    name = json_date['username']

    sqlString = "SELECT * FROM justdiscover.users WHERE user_name = '" + name + "';"
    cursor.execute(sqlString)

    DBres = cursor.fetchone()

    result = DBres[3]
    #{"pref_0":res[6], "pref_1":res[7], "pref_2":res[8], "pref_3":res[9], "pref_4":res[10], "pref_5":res[11], "pref_6":res[12]}

    #res2 = json.dumps(result)
    res = json.loads(result)

    temp = {"Museum": res['Museum'], "Parks": res['Parks'], "Ferris_wheel": res['FerrisWheel']}

    result = json.dumps(temp)

    conn.commit()
    cursor.close()
    conn.close()

    return Response(status=200, headers={"Prefs":result},  content_type='text/json')

@app.route('/api/update-preferences/', methods=['POST'])
def update_preferences():
    json_date = request.get_json(force=True)

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    #pref = json.load(json_date)
    name = json_date['username']
    pref_0 = str(json_date['Museum'])
    pref_1 = str(json_date['Parks'])
    pref_2 = str(json_date['Ferris_wheel'])

    tempstring = '{"Museum": ' + pref_0 + ', "Parks": ' + pref_1 + ', "FerrisWheel": ' + pref_2 + '}'

    sqlString = "UPDATE justdiscover.users SET preferences = '" + tempstring + "' WHERE user_name = CAST ('" + name + "' as TEXT);"
    cursor.execute(sqlString)



    conn.commit()
    cursor.close()
    conn.close()
    return Response(status=200)



@app.route('/api/give-review/', methods=['POST'])
def give_review():
    json_data = request.get_json(force=True)

    rating = json_data['rating']
    date = json_data['date']
    triptype = json_data['triptype']
    attraction = json_data['attraction']
    username = json_data['username']

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    maxIDSQL = "SELECT MAX(id) FROM justdiscover.reviews;"
    attracIDSQL = "SELECT id FROM justdiscover.poi WHERE name = '" + attraction + "';"
    userIDSQL = "SELECT id FROM justdiscover.users WHERE user_name = '" + username + "';"

    cursor.execute(maxIDSQL)
    reviewID = cursor.fetchone()
    rID = reviewID[0]
    rID = rID + 1
    cursor.execute(attracIDSQL)
    poiID = cursor.fetchone()[0]
    cursor.execute(userIDSQL)
    userID = cursor.fetchone()[0]

    insertSQL = "INSERT INTO justdiscover.reviews VALUES " + str(rID) + ", " + str(rating) + ", " + date + ", " + triptype + ", " + userID + ", " + str(poiID) + ";"
    #cursor.execute(insertSQL)



    conn.commit()
    cursor.close()
    conn.close()

    return Response(content_type='text/json', status=200)


@app.route('/api/request-all-attractions/', methods=['POST'])
def get_all_recommendations():
    json_data = request.get_json(force=True)

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    coordinate = json_data['coordinate']
    dist = json_data['dist']
    max_dist_in_m = dist * 1000
    attracs = []

    sqlstring = "SELECT * FROM justdiscover.poi_backup WHERE ST_Distance_Sphere(geometry(justdiscover.poi_backup.location_coordinate), st_makepoint " + str(coordinate) + ") <= " + str(max_dist_in_m) + ";"
    cursor.execute(sqlstring)
    attractions = cursor.fetchall()

    for attraction in attractions:
        t = attraction[12]
        t = t[1:]
        t = t[:len(t) - 1]
        c = t.split(',')
        dblat = c[0]
        dblong = c[1]

        tempAttraction = {"id": attraction[0],
                          "name": attraction[9],
                          "opening_hours": attraction[4],
                          "img_path": attraction[8],
                          "description": attraction[9],
                          "rating": float(attraction[3]),
                          "isFoodPlace": attraction[11],
                          "url": attraction[8],  # Skal ikke være det her....
                          "lat": float(dblat),
                          "long": float(dblong)}
        attracs.append(tempAttraction)
        cursor.fetchone()

    attracs = json.dumps(attracs)

    conn.commit()
    cursor.close()
    conn.close()

    return Response(headers={"attractions": attracs}, content_type='text/json', status=200)


@app.route('/api/update-liked-attractions/', methods=['POST'])
def update_liked():
    json_data = request.get_json(force=True)

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()
    username = str(json_data['username'])
    attractions = json_data['liked']

    sqlString = "UPDATE justdiscover.users SET liked_attractions = '" + attractions + "'  WHERE user_name = CAST ('" + username + "' as TEXT);"
    cursor.execute(sqlString)

    conn.commit()
    cursor.close()
    conn.close()

    return Response(content_type='text/json', status=200)



@app.route('/api/request-liked-attractions/', methods=['POST'])
def get_liked_attractions():
    json_data = request.get_json(force=True)

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()
    username = str(json_data['username'])

    sqlstring = "SELECT liked_attractions from justdiscover.users WHERE user_name = '" + username + "';"
    cursor.execute(sqlstring)
    if(cursor.rowcount == 0):
        return Response(status=200)
    attracs = []

    liked = cursor.fetchone()[0]

    if(liked != None):
        like = liked.split('|')

        like.pop(len(like)-1)


        for r in like:
            sqlstring = "SELECT * FROM justdiscover.poi_backup WHERE id = " + str(r) + ";"
            cursor.execute(sqlstring)
            attraction = cursor.fetchone()

            t = attraction[12]
            t = t[1:]
            t = t[:len(t) - 1]
            c = t.split(',')
            dblat = c[0]
            dblong = c[1]

            tempAttraction = {"id": attraction[0],
                              "name": attraction[9],
                              "opening_hours": attraction[4],
                              "img_path": attraction[8],
                              "description": attraction[9],
                              "rating": float(attraction[3]),
                              "isFoodPlace": attraction[11],
                              "url": attraction[14],
                              "lat": float(dblat),
                              "long": float(dblong),
                              "phone_number": attraction[13]}
            attracs.append(tempAttraction)

        attracs = json.dumps(attracs)

        conn.commit()
        cursor.close()
        conn.close()

    return Response(headers={"attractions": attracs}, content_type='text/json', status=200)


@app.route('/api/request-recommendations/', methods=['POST'])
def get_recommendations():

    json_data = request.get_json(force=True)
    threshold_min_rating = 3
    max_dist = json_data['dist']
    user_id = json_data['id']
    context = json_data['context']
    coordinate = json_data['coordinate']

    max_dist_in_km = max_dist * 1000

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()
    sqlString = "SELECT poi_backup.id FROM justdiscover.poi_backup WHERE ST_Distance_Sphere(geometry(justdiscover.poi_backup.location_coordinate), st_makepoint " + str(coordinate) + ") <= " + str(max_dist_in_km) + ";"
    cursor.execute(sqlString)
    poi_within_distance_list = [tup[0] for tup in list(cursor)]
    recommendation_list = icamf_recommender.top_recommendations(user_id, poi_within_distance_list, context, threshold_min_rating)

    attracs = []

    for r in recommendation_list:
        sqlstring = "SELECT * FROM justdiscover.poi_backup WHERE id = " + str(r[0]) + ";"
        cursor.execute(sqlstring)
        attraction = cursor.fetchone()
        sqlstring = "SELECT st_distance_sphere(geometry(a.location_coordinate), st_makepoint " + str(coordinate) + ") FROM justdiscover.poi_backup a WHERE a.id = " + str(r[0]) + ";"
        cursor.execute(sqlstring)
        distance = cursor.fetchone()

        t = attraction[12]
        t = t[1:]
        t = t[:len(t) - 1]
        c = t.split(',')
        dblat = c[0]
        dblong = c[1]

        tempAttraction = {"id":attraction[0],
                          "name": attraction[9],
                          "opening_hours": attraction[4],
                          "img_path": attraction[8],
                          "description": attraction[9],
                          "rating": float(attraction[3]),
                          "score": float(r[1]),
                          "isFoodPlace": attraction[11],
                          "url": attraction[14],
                          "lat": float(dblat),
                          "long": float(dblong),
                          "distance": float(distance[0]),
                          "phone_number": attraction[13]}
        attracs.append(tempAttraction)

    attracs = json.dumps(attracs)

    conn.commit()
    cursor.close()
    conn.close()

    return Response(headers={"attractions": attracs}, content_type='text/json', status=200)



@app.route('/api/create-user/', methods=['POST'])
def create_user():
    json_data = request.get_json(force=True)
    if len(json_data) != 2:
        return str(400)
    elif "password" not in json_data:
        return str(400)
    elif "username" not in json_data:
        return str(400)

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()
    sqlstring = "SELECT user_name FROM justdiscover.users WHERE user_name = '" + json_data['username'] + "';"
    cursor.execute(sqlstring)
    name = cursor.fetchone()

    if(name == None):
        now = datetime.datetime.now()
        date = str(now.year) + '-' + str(now.month) + '-' + str(now.day)
        stringid = ''
        sqlstring = "INSERT INTO justdiscover.users VALUES '', " + json_data['password'] + ", "+  date + ", '', " + json_data['username'] + ";"
        #cursor.execute(sqlstring)
        sqlstring2 = "SELECT id_sk FROM justdiscover.users WHERE user_name = '" + str(json_data['username']) + "';"
        print(json_data['username'] + ' - ' + json_data['password'] + ' | Created')
        cursor.execute(sqlstring2)
        idsk = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        return Response(status=200, headers={"id": idsk[0]}, content_type='text/json')
    else:
        return Response(status=208)

    #cursor.execute("INSERT INTO justdiscover.users VALUES (json_data['uid'],json_data['password'],current_date(),json_data['preferences'],json_data['username'])")
    conn.commit()
    cursor.close()
    conn.close()
    return str(418)


@app.route('/api/login/', methods=['POST'])
def login():
    json_data = request.get_json()
    if len(json_data) != 2:
        return 400
    elif "username" not in json_data:
        return 400
    elif "password" not in json_data:
        return 400

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()
    tempUser = cursor.execute("SELECT * FROM justdiscover.users WHERE user_name = %s AND password = %s",
                   (json_data['username'], json_data['password']))
    result = cursor.fetchone()

    res = json.dumps({"id": result[5], "t": 0})

    if (result != None):
        cursor.close()
        conn.close()
        return Response(status=200, headers={"id": res}, content_type='text/json')
    else:
        cursor.close()
        conn.close()
        return Response(status=204)


@app.route('/')
def hello_world():
    return 'Hello World!'


@app.route('/api/test/', methods=['GET'])
def test():

    insert_poi_details()



    return Response(status=200)



def update_binary_review_table():
    dataprocessor.transform_reviews_table_to_binary()


def train_recommender_kfold(kfold, regularizer, learning_rate, num_factors, iterations):
    recommender.train_eval_parallel(k_fold=kfold, regularizer=regularizer, learning_rate=learning_rate,
                                    num_factors=num_factors, iterations=iterations)


def train_and_save_model(regularizer, learning_rate, num_factors, iterations):
    recommender.train_and_save_model(regularizer=regularizer, learning_rate=learning_rate,
                                     num_factors=num_factors,iterations=iterations)


def place_details():
    api_key = "Insert_API_KEY"
    poi_place_details_list = list()
    poi_no_results = list()
    params = dict()
    params['key'] = api_key
    endpoint = "https://maps.googleapis.com/maps/api/place/details/json"
    with open("poi_id_geocoding.pkl", "rb") as f:
        id_geocoding_json_list = dill.load(f)

    for poi_id, geocoding in id_geocoding_json_list:
        if geocoding['status'] == "ZERO_RESULTS":
            poi_no_results.append(poi_id)
            continue
        params['placeid'] = geocoding["results"][0]["place_id"]
        r = requests.get(url=endpoint, params=params, )
        data = r.json()
        poi_place_details_list.append((poi_id,data))
    for empty_poi in poi_no_results:
        poi_place_details_list.append((empty_poi, None))
    with open(f'poi_details.pkl', "wb") as file:
        dill.dump(poi_place_details_list, file)
    return poi_place_details_list

def geocoding_of_poi():
    api_key = "Insert_API_KEY"
    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    cursor.execute("SELECT justdiscover.poi_backup.id,justdiscover.poi_backup.name, justdiscover.poi_backup.address FROM justdiscover.poi_backup")
    id_name_address_tuple_list = list()
    while True:
        row = cursor.fetchone()
        if row is None:
            break
        poi_id = row[0]
        name = row[1]
        address = row[2]
        id_name_address_tuple_list.append((poi_id,name,address))

    id_geocoding_json_list = list()
    params = dict()
    params['key'] = api_key
    endpoint = "https://maps.googleapis.com/maps/api/geocode/json"
    for tuple in id_name_address_tuple_list:
        location = tuple[1] + " " + tuple[2]
        params['address'] = location
        r = requests.get(url=endpoint, params=params, )
        data = r.json()
        id_geocoding_json_list.append((tuple[0],data))
    cursor.close()
    conn.close()

    return id_geocoding_json_list

def insert_poi_details():
    with open("poi_details.pkl", "rb") as f:
        poi_details = dill.load(f)
    poi_no_details_list = list()
    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    for poi_id, details_json in poi_details:
        if details_json is None:
            poi_no_details_list.append((poi_id, details_json))
            continue
        phone_number = None
        categories = None
        website = None
        opening_hours = None
        price_level = None

        if 'international_phone_number' in details_json['result']:
            phone_number = details_json['result']['international_phone_number']
            sqlstring = "UPDATE justdiscover.poi_backup SET phonenumber = '" + str(phone_number) + "' WHERE justdiscover.poi_backup.id = " + str(poi_id) +";"
            #cursor.execute(sqlstring)
        if 'types' in details_json['result']:
            categories = details_json['result']['types']
            sqlstring = "UPDATE justdiscover.poi_backup SET category = '" + json.dumps(categories) + "' WHERE justdiscover.poi_backup.id = " + str(poi_id) +";"
            #cursor.execute(sqlstring)
        if 'website' in details_json['result']:
            website = details_json['result']['website']
            sqlstring = "UPDATE justdiscover.poi_backup SET url = '" + website + "' WHERE justdiscover.poi_backup.id = " + str(poi_id) +";"
            #cursor.execute(sqlstring)
        if 'opening_hours' in details_json['result']:
            opening_hours = details_json['result']['opening_hours']['weekday_text']
            sqlstring = "UPDATE justdiscover.poi_backup SET open_hours = '" + json.dumps(opening_hours) + "' WHERE justdiscover.poi_backup.id = " + str(poi_id) +";"
            #cursor.execute(sqlstring)
        if 'price_level' in details_json['result']:
            price_level = details_json['result']['price_level']
            sqlstring = "UPDATE justdiscover.poi_backup SET price_level = '" + str(price_level) + "' WHERE justdiscover.poi_backup.id = " + str(poi_id) +";"
            #cursor.execute(sqlstring)

    #conn.commit()
    #cursor.close()
    #conn.close()



def insert_geocoding_database():
    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()
    id_geocoding_json_list = pickle.load(open("poi_id_geocoding.pkl", "rb"))
    poi_no_results = list()
    for poi_id, geocoding in id_geocoding_json_list:
        if geocoding['status'] == "ZERO_RESULTS":
            poi_no_results.append(poi_id)
            continue
        formatted_address = geocoding['results'][0]['formatted_address']
        latitude = geocoding['results'][0]['geometry']['location']['lat']
        longitude = geocoding['results'][0]['geometry']['location']['lng']
        point = (latitude, longitude)
        cursor.execute("UPDATE justdiscover.poi_backup SET address = %s, location_coordinate = POINT %s WHERE justdiscover.poi_backup.id = %s ", (formatted_address, (point), poi_id))

    conn.commit()
    cursor.close()
    conn.close()


if __name__ == '__main__':

    app.run()


with open("dummy_model.pkl", "rb") as f:
    icamf_recommender = dill.load(f)

#train_and_save_model(0.001,0.002,25,20)
#train_recommender_kfold(5, 0.001, 0.002,25,100)
#train_recommender_kfold(5, 0.001, 0.002,25,100)
#train_recommender_kfold(5, 0.001, 0.002,25,100)

