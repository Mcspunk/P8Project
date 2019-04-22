import 'package:flutter/material.dart';

void displayMsg(String msg, BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
        );
      });
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
  double _rating;
  bool _isFoodPlace;

  Attraction(String name, String openingHours, String imgPath, bool isFoodPlace, [double rating]){
    _name = name;
    _openingHours = openingHours;
    _imgPath = imgPath;
    rating != null ? _rating = rating : _rating = 0;
    _isFoodPlace = isFoodPlace;
  }

  String GetName(){
    return _name;
  }
  String GetOpeningHours(){
    return _openingHours;
  }
  String GetImgPath(){
    return _imgPath;
  }
  double GetRating(){
    return _rating;
  }
  bool GetIsFoodPlace(){
    return _isFoodPlace;
  }

}
