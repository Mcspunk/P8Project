from flask import Flask, make_response
import json
from flask_cors import CORS
from flask import request, Response
import psycopg2 as psy
import datetime
import math

host = "jd-database.ccwvupidct47.eu-west-3.rds.amazonaws.com"
database = "jd_database"
user = "palminde"
password = "sw_809_p8"

app = Flask(__name__)
cors = CORS(app, support_credentials=True, resources={r"/api/*": {"origins": "*", "support_credentials": True}})


@app.route('/api/get-preferences/', methods=['POST'])
def get_preferences():
    json_date = request.get_json(force=True)
    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    name = json_date['username']

    sqlString = "SELECT * FROM justdiscover.users WHERE user_name = '" + name + "';"
    cursor.execute(sqlString)

    res = cursor.fetchone()

    result = {"pref_0":res[6], "pref_1":res[7], "pref_2":res[8], "pref_3":res[9], "pref_4":res[10], "pref_5":res[11], "pref_6":res[12]}
    result = json.dumps(result)

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
    pref_0 = str(json_date['pref_0'])
    pref_1 = str(json_date['pref_1'])
    pref_2 = str(json_date['pref_2'])
    pref_3 = str(json_date['pref_3'])
    pref_4 = str(json_date['pref_4'])
    pref_5 = str(json_date['pref_5'])
    pref_6 = str(json_date['pref_6'])

    sqlString = "UPDATE justdiscover.users SET pref_0 = " + pref_0 + ", pref_1 = " + pref_1 + ", pref_2 = " + pref_2 + ", pref_3 = " + pref_3 + ", pref_4 = " + pref_4 + ", pref_5 = " + pref_5 + ", pref_6 = " + pref_6 + " WHERE user_name = CAST ('" + name + "' as TEXT);"
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
    userIDSQL = "SELECT id FROM justdiscover.users WHERE user_name = '"+ username + "';"

    TreviewID = cursor.execute(maxIDSQL)
    reviewID = cursor.fetchone()
    rID = reviewID[0]
    rID = rID + 1
    TpoiID = cursor.execute(attracIDSQL)
    poiID = cursor.fetchone()[0]
    TuserID = cursor.execute(userIDSQL)
    userID = cursor.fetchone()[0]

    insertSQL = "INSERT INTO justdiscover.reviews VALUES " + str(rID) + ", " + str(rating) + ", " + date + ", " + triptype + ", " + userID + ", " + str(poiID) + ";"
    #cursor.execute(insertSQL)



    conn.commit()
    cursor.close()
    conn.close()

    return Response(content_type='text/json', status=200)


@app.route('/api/request-all-recommendations/', methods=['POST'])
def get_all_recommendations():
    json_data = request.get_json(force=True)

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    lat = json_data['lat']
    long = json_data['long']
    dist = json_data['dist']

    latDegree = math.radians(lat)
    longDegree = math.radians(long)
    kmAtEq = 69.172*1.609
    longdist = (1/1.38458)*((((dist/(((lat*math.pi)/180)*kmAtEq))/kmAtEq)*180)/math.pi)
    latdist = dist/kmAtEq


    maxlong = long + longdist
    minlong = long - longdist
    maxlat = lat + latdist
    minlat = lat - latdist


    #Det her skal være alle dem inden for en hvis radius
    recs = []     #1, 3, 5, 2, 22, 10, 12, 32, 99, 23, 41]
    attracs = []

    sqlstring = "SELECT * FROM justdiscover.poi WHERE lat > "+ str(minlat) +" AND lat < " + str(maxlat) +" AND lng > " + str(minlong) +" AND lng < " + str(maxlong) + ";"

    cursor.execute(sqlstring)

    attraction = cursor.fetchone
    counter = 0

    #Linjen her under skal fjernes når db er good to go
    return Response(headers={"attractions": attracs}, content_type='text/json', status=200)


    while(attraction != None and counter < 20):
        #sqlstring = "SELECT * FROM justdiscover.poi WHERE id = " + str(r) + ";"
        #cursor.execute(sqlstring)
        #attraction = cursor.fetchone()
        tempAttraction = {"name": attraction[9],
                          "opening_hours": attraction[4],
                          "img_path": attraction[8],
                          "description": attraction[9],
                          "rating": float(attraction[3]),
                          "isFoodPlace": attraction[11],
                          "url": attraction[8],  # Skal ikke være det her....
                          "lat": float(attraction[1]),
                          "long": float(attraction[2])}
        attracs.append(tempAttraction)
        cursor.fetchone
        counter += 1

    attracs = json.dumps(attracs)

    conn.commit()
    cursor.close()
    conn.close()

    return Response(headers={"attractions": attracs}, content_type='text/json', status=200)


@app.route('/api/request-recommendations/', methods=['POST'])
def get_recommendations():
    json_data = request.get_json(force=True)

    conn = psy.connect(host=host, database=database, user=user, password=password)
    cursor = conn.cursor()

    dist = json_data['dist']

    #Kald recommendation metoden her sådan at den liste der bliver returneret bliver sat til at være lig recs
    recs = [1, 3, 5, 2, 22, 10]
    attracs = []

    for r in recs:
        sqlstring = "SELECT * FROM justdiscover.poi WHERE id = " + str(r) + ";"
        cursor.execute(sqlstring)
        attraction = cursor.fetchone()
        tempAttraction = {"name": attraction[9],
                          "opening_hours": attraction[4],
                          "img_path": attraction[8],
                          "description": attraction[9],
                          "rating": float(attraction[3]),
                          "isFoodPlace": attraction[11],
                          "url": attraction[8],  # Skal ikke være det her....
                          "lat": float(attraction[1]),
                          "long": float(attraction[2])}
        attracs.append(tempAttraction)

    attracs = json.dumps(attracs)

    conn.commit()
    cursor.close()
    conn.close()

    return Response(headers={"attractions": attracs}, content_type='text/json', status=200)
    #return str(200), {"attractions": result}, {"Content-Type": "application/json"}


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
    name = cursor.execute(sqlstring)

    if(name == None):
        now = datetime.datetime.now()
        date = str(now.year) + '-' + str(now.month) + '-' + str(now.day)
        sqlstring = "INSERT INTO justdiscover.users VALUES '', " + json_data['password'] + ", "+  date + ", '', " + json_data['username'] + ";"
        #cursor.execute(sqlstring)
        print(json_data['username'] + ' - ' + json_data['password'] + ' | Created')
        conn.commit()
        cursor.close()
        conn.close()
        return str(200)
    else:
        return str(208)

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
    cursor.close()
    conn.close()
    if (tempUser != None):
        return str(200)
    else:
        return str(204)


@app.route('/')
def hello_world():
    return 'Hello World!'


if __name__ == '__main__':
    app.run()