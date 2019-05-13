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

Future<bool> loadWantsDistancePenalty() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('wantDistPen');
}

void saveWantsDistancePenalty(bool val) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('wantDistPen', val);
}

Future<int> loadMaxDistance() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int res = prefs.getInt('dist');
  return res;
}

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

Future<void> giveReview(double rating, DateTime date, String triptype,
    String attraction, BuildContext context) async {
  Map months = {
    1: "January",
    2: "Febuary",
    3: "March",
    4: "April",
    5: "May",
    6: "June",
    7: "July",
    8: "August",
    9: "September",
    10: "October",
    11: "November",
    12: "December"
  };
  String _date = months[date.month] + " " + date.year.toString();
  var preEncode = {
    "rating": rating,
    "date": _date,
    "triptype": triptype,
    "attraction": attraction,
    "username": await loadString("currentUser")
  };
  var postEncode = jsonEncode(preEncode);
  try {
    var response = await http.post('http://10.0.2.2:5000/api/give-review/',
        body: postEncode, headers: {"Content-Type": "application/json"});

    if (response.statusCode != 200) {
      print('Error: ' + response.statusCode.toString());
    }
  } catch (e) {
    print(e);
  }
}

Future<void> updatePreferences(BuildContext context) async {
  DataContainer data = DataProvider.of(context).dataContainer;
  var ratings = data.getCategoryRatings();
  var preEncode = {
    "username": await loadString('currentUser'),
    "Museum": ratings['Museum'],
    "Parks": ratings['Parks'],
    "Ferris_wheel": ratings['Ferris Wheel'],
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
    print(e);
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

    data.getCategoryRatings()['Museum'] = prefspost['Museum'];
    data.getCategoryRatings()['Parks'] = prefspost['Parks'];
    data.getCategoryRatings()['Ferris Wheel'] = prefspost['Ferris_wheel'];
  } catch (e) {
    print(e);
  }
}

Future<int> getRecCount(Coordinate coordinate) async {
  var jsonstring = {
    "lat": coordinate.GetLat(),
    "long": coordinate.GetLong(),
    "distance": await loadString("dist")
  };
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
  } catch (e) {
    print(e);
  }
  return 0;
}

Future<void> getAllAttractions(
    Coordinate coordinate, int dist, BuildContext context) async {
  var jsonstring = {
    "lat": coordinate.GetLat(),
    "long": coordinate.GetLong(),
    "dist": dist ?? 1
  };
  var jsonedString = jsonEncode(jsonstring);
  try {
    var response = await http.post(
        'http://10.0.2.2:5000/api/request-all-recommendations/',
        body: jsonedString,
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      var attracts = response.headers['attractions'];
      var decoded = attracts == null ? [] : jsonDecode(attracts);
      var t = decoded as List;
      List<Attraction> recAttractions = [];
      for (var i = 0; i < t.length; i++) {
        recAttractions.add(new Attraction(
            t[i]['id'],
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
      displayMsg('No connection to server.\nGAA', context);
    }
  } catch (e) {
    print(e);
  }
}

Future<void> getRecommendations(
    Coordinate coordinate, int dist, BuildContext context) async {
  /*var jsonstring = {
    "lat": coordinate.GetLat(),
    "long": coordinate.GetLong(),
    "dist": dist ?? 1
  };
  var jsonedString = jsonEncode(jsonstring);
  try {
    var response = await http.post(
        'http://10.0.2.2:5000/api/request-recommendations/',
        body: jsonedString,
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      var attracts = response.headers['attractions'];
      var decoded = attracts == null ? [] : jsonDecode(attracts);
      var t = decoded as List;
      List<Attraction> recAttractions = [];
      for (var i = 0; i < t.length; i++) {
        recAttractions.add(new Attraction(
            t[i]['id'],
            t[i]['name'],
            t[i]['opening_hours'],
            t[i]['img_path'],
            !t[i]['isFoodPlace'],
            t[i]['rating'],
            t[i]['description'],
            t[i]['url'],
            t[i]['lat'],
            t[i]['long']));
      }*/
      List<Attraction> recAttractions = [];
      recAttractions.add(Attraction(1, 'test', 'opening', 'https://i.imgur.com/YuQ9fu2.jpg', true, 5.0, 'desc', 'https://i.imgur.com/YuQ9fu2.jpg', 37.787834, -122.406417));
      DataContainer data = DataProvider.of(context).dataContainer;
      if (recAttractions.length != 0) {
        data.setAttractions(recAttractions);
      }
      print(data.getAttractions().length);
    /*} else {
      displayMsg('No connection to server\nGR', context);
    }
  } catch (e) {
    print(e);
  }*/
}

Future<void> updateLikedAttraction(BuildContext context) async {
  DataContainer data = DataProvider.of(context).dataContainer;
  String liked = "";
  for (var item in data.getFavourites()) {
    liked += (item.GetID().toString() + "|");
  }
  if (liked.length != 0) {
    var preEncode = {
      "username": await loadString('currentUser'),
      "liked": liked
    };
    var postEncode = jsonEncode(preEncode);
    try {
      var response = await http.post(
          'http://10.0.2.2:5000/api/update-liked-attractions/',
          body: postEncode,
          headers: {"Content-Type": "application/json"});
      if (response.statusCode != 200) {
        displayMsg('Error: ' + response.statusCode.toString(), context);
      }
    } catch (e) {
      print(e);
    }
  }
}

Future<void> getLikedAttraction(BuildContext context) async {
  var jsonstring = {"username": await loadString('currentUser')};
  var jsonedString = jsonEncode(jsonstring);
  try {
    var response = await http.post(
        'http://10.0.2.2:5000/api/request-liked-attractions/',
        body: jsonedString,
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      var attracts = response.headers['attractions'];
      var decoded = attracts == null ? [] : jsonDecode(attracts);
      var t = decoded as List;
      List<Attraction> recAttractions = [];
      for (var i = 0; i < t.length; i++) {
        recAttractions.add(new Attraction(
            t[i]['id'],
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
        data.setFavourites(recAttractions);
      }
    } else {
      displayMsg('No connection to server.\nGLA', context);
    }
  } catch (e) {
    print(e);
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
      saveString('currentUser', username.toString());
      getPreferences(context);
      Navigator.pushNamed(context, '/');
    } else if (response.statusCode == 204) {
      displayMsg(
          'Coulnd\'t find a user with that username, or the password was wrong',
          context);
    } else {
      displayMsg('No connection to server.\nLI', context);
    }
  } catch (e) {
    print(e);
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
      saveString('currentUser', username.toString());
      Navigator.pushNamed(context, '/select_interests');
    } else if (response.statusCode == 208) {
      displayMsg('Username already taken.', context);
    } else {
      displayMsg('No connection to server.\nSU', context);
    }
  } catch (e) {
    print(e);
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
    displayMsg('Could not connect to $url', context);
  }
}

Coordinate findMiddlePoint(Coordinate one, Coordinate two) {
  double latdiff =
      one.GetLat() < two.GetLat() ? two.GetLat() - one.GetLat() : one.GetLat() - two.GetLat();
  double longdiff =
      one.GetLong() < two.GetLong() ? two.GetLong() - one.GetLong() : one.GetLong() - two.GetLong();
  longdiff = longdiff / 2;
  latdiff = latdiff / 2;
  double lat = one.GetLat() < two.GetLat() ? one.GetLat() + latdiff : two.GetLat() + latdiff;
  double long =
      one.GetLong() < two.GetLong() ? one.GetLong() + longdiff : two.GetLong() + longdiff;
  return new Coordinate(lat, long);
}

double distanceBetweenCoordinates(Coordinate c1, Coordinate c2) {
  var r = 6371000;
  double phi_1 = c1.GetLat() * (pi / 180);
  double phi_2 = c2.GetLat() * (pi / 180);
  double deltaPhi = (c2.GetLat() - c1.GetLat()) * (pi / 180);
  double deltaLambda = (c2.GetLong() - c1.GetLong()) * (pi / 180);
  var a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
      cos(phi_1) * cos(phi_2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
  var c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double zoomLevel(double distance) {
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
  int _id;
  String _name;
  String _openingHours;
  String _imgPath;
  String _description;
  double _rating;
  bool _isFoodPlace;
  String _url;
  Coordinate _coordinate;
  double _penalisedScore;

  Attraction(int id, String name, String openingHours, String imgPath,
      bool isFoodPlace,
      [double rating,
      String description,
      String url,
      double lat,
      double long,]) {
    _id = id;
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

  double GetPenalisedScore() {
    return _penalisedScore;
  }

  void SetPenalisedScore(val) {
    _penalisedScore = val;
  }

  int GetID() {
    return _id;
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
  bool operator ==(other) {
    return (other is Attraction && this._id == other.GetID());
  }
}
