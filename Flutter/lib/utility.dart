import 'package:flutter/material.dart';
import 'package:test2/data_container.dart';
import 'package:test2/data_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math';

ThemeData utilTheme() {
  return ThemeData(
    // Define the default Brightness and Colors
    brightness: Brightness.dark,
    primaryColor: Colors.grey[850],
    accentColor: Colors.green,
    //backgroundColor: Colors.grey[300],

    primaryColorDark: Colors.grey[800],

    hintColor: Colors.grey[500],

    // Define the default Font Family
    fontFamily: 'Montserrat',

    // Define the default TextTheme. Use this to specify the default
    // text styling for headlines, titles, bodies of text, and more.
    textTheme: TextTheme(
      headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
      title: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
      body1: TextStyle(fontSize: 14.0, fontFamily: 'Hind', color: Colors.black),
      body2: TextStyle(
          fontSize: 14.0, fontFamily: 'Hind', color: Colors.grey[300]),
    ),
  );
}

Future<void> updatePreferences(BuildContext context) async {
  DataContainer data = DataProvider.of(context).dataContainer;

  var ratings = data.getCategoryRatings();

  var preEncode = {
    "username": await loadString('currentUser'),
    "pref_0": ratings['pref_0'],
    "pref_1": ratings['pref_1'],
    "pref_2": ratings['pref_2'],
    "pref_3": ratings['pref_3'],
    "pref_4": ratings['pref_4'],
    "pref_5": ratings['pref_5'],
    "pref_6": ratings['pref_6']
  };

  var postEncode = jsonEncode(preEncode);

  try {
    var response = await http.post(
        'http://10.0.2.2:5000/api/update-preferences/',
        body: postEncode,
        headers: {"Content-Type": "application/json"});

    if (response.statusCode != 200) {
      displayMsg('Error: ' + response.statusCode.toString(), context);
    }
  } catch (e) {
    displayMsg(e, context);
  }
}

Future<void> getPreferences(BuildContext context) async {
  DataContainer data = DataProvider.of(context).dataContainer;

  try {
    String user = await loadString('currentUser');
    var preEncode = {"username": user, "un": user};
    var postEncode = jsonEncode(preEncode);
    var response = await http.post('http://10.0.2.2:5000/api/get-preferences/',
        body: postEncode, headers: {"Content-Type": "application/json"});

    var prefspre = response.headers['prefs'];
    var prefspost = jsonDecode(prefspre);
    data.getCategoryRatings()['pref_0'] = prefspost['pref_0'];
    data.getCategoryRatings()['pref_1'] = prefspost['pref_1'];
    data.getCategoryRatings()['pref_2'] = prefspost['pref_2'];
    data.getCategoryRatings()['pref_3'] = prefspost['pref_3'];
    data.getCategoryRatings()['pref_4'] = prefspost['pref_4'];
    data.getCategoryRatings()['pref_5'] = prefspost['pref_5'];
    data.getCategoryRatings()['pref_6'] = prefspost['pref_6'];
  } catch (e) {
    displayMsg(e, context);
  }
}

Future<int> getRecCount(Coordinate coordinate) async {
  var jsonstring = {"lat": coordinate.GetLat(), "long": coordinate.GetLong()};
  var jsonedString = jsonEncode(jsonstring);
  try {
    var response = await http.post(
        'http://10.0.2.2:5000/api/request-recommendations/',
        body: jsonedString,
        headers: {"Content-Type": "application/json"});
    var attracts = response.headers['attractions'];
    var decoded = jsonDecode(attracts);
    var t = decoded as List;
    return t.length;
  }
  catch(e){
    print(e);
  }
  return 0;
}

Future<void> getAllAttractions(Coordinate coordinate, BuildContext context) async{
    var jsonstring = {"lat": coordinate.GetLat(), "long": coordinate.GetLong()};
  var jsonedString = jsonEncode(jsonstring);
  try {
    var response = await http.post(
        'http://10.0.2.2:5000/api/request-all-recommendations/',
        body: jsonedString,
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      var attracts = response.headers['attractions'];
      var decoded = jsonDecode(attracts);
      var t = decoded as List;
      List<Attraction> recAttractions = [];
      for (var i = 0; i < t.length; i++) {
        recAttractions.add(new Attraction(
            t[i]['name'],
            t[i]['opening_hours'],
            t[i]['img_path'],
            !t[i]['isFoodPlace'],
            t[i]['rating'],
            t[i]['description'],
            t[i]['url'],
            t[i]['lat'],
            t[i]['long']));
      }

      DataContainer data = DataProvider.of(context).dataContainer;
      if (recAttractions.length != 0) {
        data.setAllNearbyAttractions(recAttractions);
      }
    } else {
      displayMsg('No connection to server.', context);
    }
  } catch (e) {
    displayMsg(e.toString(), context);
  }
}

Future<void> getRecommendations(
    Coordinate coordinate, BuildContext context) async {
  var jsonstring = {"lat": coordinate.GetLat(), "long": coordinate.GetLong()};
  var jsonedString = jsonEncode(jsonstring);
  try {
    var response = await http.post(
        'http://10.0.2.2:5000/api/request-recommendations/',
        body: jsonedString,
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      var attracts = response.headers['attractions'];
      var decoded = jsonDecode(attracts);
      var t = decoded as List;
      List<Attraction> recAttractions = [];
      for (var i = 0; i < t.length; i++) {
        recAttractions.add(new Attraction(
            t[i]['name'],
            t[i]['opening_hours'],
            t[i]['img_path'],
            !t[i]['isFoodPlace'],
            t[i]['rating'],
            t[i]['description'],
            t[i]['url'],
            t[i]['lat'],
            t[i]['long']));
      }

      DataContainer data = DataProvider.of(context).dataContainer;
      if (recAttractions.length != 0) {
        data.setAttractions(recAttractions);
      }

    } else if (response.statusCode == 208) {
      displayMsg('Username already taken.', context);
    } else {
      displayMsg('No connection to server.', context);
    }
  } catch (e) {
    displayMsg(e.toString(), context);
  }
}

Future<void> checkLogIn(
    String username, String password, BuildContext context) async {
  var jsonstring = {"username": username, "password": password};
  var jsonedString = jsonEncode(jsonstring);
  try {
    var response = await http.post('http://10.0.2.2:5000/api/login/',
        body: jsonedString, headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      saveString('currentUser', username);
      getPreferences(context);
      Navigator.pushNamed(context, '/');
    } else if (response.statusCode == 204) {
      displayMsg(
          'Coulnd\'t find a user with that username, or the password was wrong',
          context);
    } else {
      displayMsg('No connection to server.', context);
    }
  } catch (e) {
    displayMsg(e.toString(), context);
  }
}

Future<void> checkSignUp(
    String username, String password, BuildContext context) async {
  var jsonstring = {"username": username, "password": password};
  var jsonedString = jsonEncode(jsonstring);
  try {
    var response = await http.post('http://10.0.2.2:5000/api/create-user/',
        body: jsonedString, headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      saveString('currentUser', username);
      Navigator.pushNamed(context, '/select_interests');
    } else if (response.statusCode == 208) {
      displayMsg('Username already taken.', context);
    } else {
      displayMsg('No connection to server.', context);
    }
  } catch (e) {
    displayMsg(e.toString(), context);
  }
}

void clearSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.clear();
}

void deleteString(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove(key);
}

void saveString(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(key, value);
}

Future<String> loadString(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

void displayMsg(String msg, BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
        );
      });
}

void launchWebsite(String url, var context) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    displayMsg('Could not launch $url', context);
  }
}

Coordinate findMiddlePoint(Coordinate one, Coordinate two) {
  double latdiff =
      one._lat < two._lat ? two._lat - one._lat : one._lat - two._lat;
  double longdiff =
      one._long < two._long ? two._long - one._long : one._long - two._long;
  longdiff = longdiff / 2;
  latdiff = latdiff / 2;
  double lat = one._lat < two._lat ? one._lat + latdiff : two._lat + latdiff;
  double long =
      one._long < two._long ? one._long + longdiff : two._long + longdiff;
  return new Coordinate(lat, long);
}

double distanceBetweenCoordinates(Coordinate c1, Coordinate c2){
  var r = 6371000;
  double phi_1 = c1.GetLat() * (pi / 180);
  double phi_2 = c2.GetLat() * (pi / 180);
  double deltaPhi = (c2.GetLat() - c1.GetLat()) *(pi / 180);
  double deltaLambda = (c2.GetLong() - c1.GetLong()) * (pi / 180);

  var a = sin(deltaPhi/2) * sin(deltaPhi/2) + cos(phi_1) * cos(phi_2) * sin(deltaLambda/2) *sin(deltaLambda/2);
  var c = 2 * atan2(sqrt(a), sqrt(1-a));

  return r * c;
}

double zoomLevel(double distance){
  var dist = (6371000 / distance);
  return log(dist) * 1.7;
}

class Coordinate {
  double _lat;
  double _long;
  Coordinate(double lat, double long) {
    _lat = lat;
    _long = long;
  }
  double GetLat() {
    return _lat;
  }

  double GetLong() {
    return _long;
  }
}

class User {
  String name;
  String email;
  User([String nameIn, String emailIn]) {
    name = nameIn;
    email = emailIn;
  }

  @override
  String toString() {
    return 'Name: ' + name + ' \n' + 'Email : ' + email;
  }
}

class Attraction {
  String _name;
  String _openingHours;
  String _imgPath;
  String _description;
  double _rating;
  bool _isFoodPlace;
  String _url;
  Coordinate _coordinate;

  Attraction(String name, String openingHours, String imgPath, bool isFoodPlace,
      [double rating,
      String description,
      String url,
      double lat,
      double long]) {
    _name = name;
    _openingHours = openingHours;
    _imgPath = imgPath;
    rating != null ? _rating = rating : _rating = 0;
    description != null
        ? description.length < 850
            ? _description = description
            : _description = description.substring(0, 850) + '...'
        : _description = 'No information is available for this attraction';
    url != null ? _url = url : _url = null;
    lat != null && long != null
        ? _coordinate = new Coordinate(lat, long)
        : _coordinate = null;
    _isFoodPlace = isFoodPlace;
  }

  String GetName() {
    return _name;
  }

  String GetOpeningHours() {
    return _openingHours;
  }

  String GetImgPath() {
    return _imgPath;
  }

  double GetRating() {
    return _rating;
  }

  bool GetIsFoodPlace() {
    return _isFoodPlace;
  }

  String GetDescription() {
    return _description;
  }

  String GetURL() {
    return _url;
  }

  Coordinate GetCoordinate() {
    return _coordinate;
  }

  @override
  bool operator ==(other){
    return (other is Attraction && this._name == other.GetName());
  }

}
