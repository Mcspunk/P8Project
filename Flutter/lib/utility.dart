import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

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


  Future sleepX(int x) {
    for (var i = 0; i < x; i++) {
      sleepOne();
    }
  }
  Future sleepOne() {
  return new Future.delayed(const Duration(seconds: 1), () => "1");
}

void launchWebsite(String url, var context) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    displayMsg('Could not launch $url', context);
  }
}

Coordinate findMiddlePoint(Coordinate one, Coordinate two){
  double latdiff = one._lat < two._lat ? two._lat - one._lat : one._lat - two._lat;
  double longdiff = one._long < two._long ? two._long - one._long : one._long - two._long;
  longdiff = longdiff / 2;
  latdiff = latdiff / 2;
  double lat = one._lat < two._lat ? one._lat + latdiff : two._lat + latdiff;
  double long = one._long < two._long ? one._long + longdiff : two._long + longdiff;
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
