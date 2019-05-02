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


Future<int> getRecommendations(
    Coordinate coordinate, BuildContext context) async {
  //var context = ctx == null ? BuildContext : ctx;
  var jsonstring = {"lat": coordinate.GetLat(), "long": coordinate.GetLong()};
  var jsonedString = jsonEncode(jsonstring);
  try {
    var response = await http.post(
        'http://10.0.2.2:5000/api/request-recommendations/',
        body: jsonedString,
        headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      var attracts = response.headers['attractions'];
      attracts = "[" + attracts + "]";
      var decoded = jsonDecode(attracts);
      var t = decoded as List;
      var y = t[0];
      List<Attraction> recAttractions = [];
      y.forEach((k, v) => recAttractions.add(new Attraction(
          v['name'],
          v['opening_hours'],
          v['img_path'],
          v['isFoodPlace'] == "False" ? false : true,
          double.parse(v['rating']),
          v['description'],
          v['url'],
          double.parse(v['lat']),
          double.parse(v['long']))));

      DataContainer data = DataProvider.of(context).dataContainer;
      print("B-recAtt: " + recAttractions.length.toString());
      print("B-dataRac: " + data.getAttractions().length.toString());
      if (recAttractions.length != 0) {
        data.setAttractions(recAttractions);
      }
      print("A-recAtt: " + recAttractions.length.toString());
      print("A-dataRac: " + data.getAttractions().length.toString());

      return recAttractions.length;
    } else if (response.statusCode == 208) {
      displayMsg('Username already taken.', context);
    } else {
      displayMsg('No connection to server.', context);
    }
  } catch (e) {
    displayMsg(e.toString(), context);
  }

  return 0;
}

Future<void> checkSignUp(
    String username, String password, BuildContext context) async {
  var jsonstring = {"username": username, "password": password};
  var jsonedString = jsonEncode(jsonstring);
  try {
    var client = new http.Client();
    var response = await client.post('http://10.0.2.2:5000/api/create-user/',
        body: jsonedString, headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      saveString('currentUser', username);
      Navigator.pushNamed(context, '/select_interests');
      client.close();
    } else if (response.statusCode == 208) {
      displayMsg('Username already taken.', context);
    } else {
      displayMsg('No connection to server.', context);
    }
  } catch (e) {
    displayMsg(e.toString(), context);
  }
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
}
