import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

void saveCategoryRatings(String key, List<String> categories, List<double> ratings) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setStringList(key, categories);
  saveRatings('Ratings', ratings);
}

void saveRatings(String key, List<double> ratings) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> stringRatings = [];
  for (int i = 0; i < ratings.length; i++) {
    stringRatings.add(ratings[i].toString());
  }
  prefs.setStringList(key, stringRatings);
}

Future<List<String>> getListOfStrings(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(key);
}

void clearSharedPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.clear();
}

class SelectInterests extends State<InterestsState> {
  List<String> _categories = [];
  List<double> _ratings = [];

  @override
  void initState() {
    getListOfStrings('Categories').then(loadCategories);
    getListOfStrings('Ratings').then(loadRatings);
    super.initState();
  }

  void loadCategories(List<String> tripType) {
    setState(() {
      _categories = tripType ??
          ['Park', 'Zoo', 'Museum', 'Casino', 'Indian', '1', '1', '1', '1'];
    });
  }

  void loadRatings(List<String> stringRatings) {
    setState(() {
      if (stringRatings != null) {
        List<double> doubleRatings = [];
        for (int i = 0; i < stringRatings.length; i++) {
          doubleRatings.add(double.parse(stringRatings[i]));
        }
        this._ratings = doubleRatings;
      } else {
        this._ratings = [0, 0, 0, 0, 0, 0, 0, 0, 0];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate categories'),
        leading: Container(),
      ),
      body: _interestList(),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          child: Icon(
            Icons.arrow_forward,
            size: 40,
          ),
          onPressed: () {
            saveCategoryRatings('Categories', this._categories, this._ratings);
            
            Navigator.pop(context);
            Navigator.pushNamed(context, '/');
          }),
    );
  }

  Widget _interestList() {
    List<Widget> widgetList = new List<Widget>();
    widgetList.add(new ListTile(
      title: Text(
          'Please enter rating for each of the categories. The more you rate the better recommendations you will get. You can click the arrow when you dont want to rate more categories.'),
    ));
    widgetList.add(Divider());
    for (int i = 0; i < _categories.length; i++) {
      widgetList.add(new ListTile(
        title: Text(_categories[i]),
        trailing: SmoothStarRating(
            rating: _ratings[i],
            size: 25,
            starCount: 5,
            color: Colors.orange[400],
            borderColor: Colors.grey,
            onRatingChanged: (value) {
              setState(() {
                _ratings[i] = value;
              });
            }),
      ));
      widgetList.add(Divider(
        height: 20,
      ));
    }
    widgetList.add(new ListTile());
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: widgetList,
    );
  }
}

class InterestsState extends StatefulWidget {
  @override
  SelectInterests createState() => SelectInterests();
}
