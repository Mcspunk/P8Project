import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test2/data_container.dart';
import 'utility.dart';

void saveCategoryRatings(
    String key, List<String> categories, List<double> ratings) async {
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

Future<List<String>> getCategories(BuildContext context) async {
  DataContainerState data = DataContainer.of(context);
  var temp = data.getCategoryRatings().keys;
  List<String> result = [];
  for (var item in temp) {
    result.add(item);
  }  
  return result;


  //SharedPreferences prefs = await SharedPreferences.getInstance();
  //return prefs.getStringList(key);
}

Future<List<String>> getRatings(BuildContext context) async {  
  DataContainerState data = DataContainer.of(context);
  var temp = data.getCategoryRatings().values;
  List<String> result = [];
  for (var item in temp) {
    result.add(item.toString());
  }  
  return result;


  //SharedPreferences prefs = await SharedPreferences.getInstance();
  //return prefs.getStringList(key);
}

class SelectInterests extends State<InterestsState> {
  List<String> _categories = []; //'Park', 'Zoo', 'Museum', 'Casino', 'Indian', '1', '1', '1', '1'];
  List<double> _ratings = [];//0, 0, 0, 0, 0, 0, 0, 0, 0];


  @override
  void didChangeDependencies(){
    getCategories(context).then(loadCategories);
    getRatings(context).then(loadRatings);
    super.didChangeDependencies();
  }

  @override
  void initState() {    
    super.initState();
  }

  void loadCategories(List<String> categories) {    
    if(categories != null){
      setState(() {
        _categories = categories;
      });
    }    
  }

  void loadRatings(List<String> stringRatings) {
    setState(() {
      if (stringRatings != null && stringRatings.length != 0) {
        List<double> doubleRatings = [];
        for (var item in stringRatings) {
          doubleRatings.add(double.parse(item));
        }
        /*
        for (int i = 0; i < stringRatings.length; i++) {
          doubleRatings.add(double.parse(stringRatings[i]));
        }
        */
        this._ratings = doubleRatings;
      } 
      /*
      else {
        this._ratings = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      }
      */
    });
  }

  @override
  Widget build(BuildContext context) {
    getCategories(context).then(loadCategories);
    getRatings(context).then(loadRatings);
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate recommendation categories'),
      ),
      body: _interestList(),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          child: Icon(
            Icons.arrow_forward,
            size: 40,
          ),
          onPressed: () async {
            bool madeRating = false;
            for (var rating in _ratings) {
              if(rating > 0)
              madeRating = true;
            }
            if(!madeRating){
              return displayMsg('You have not given any ratings of categories. Please make ratings to proceed. Thank you :)', context);
            }



            showDialog(
              context: context,
              barrierDismissible: false,
                //mainAxisAlignment: MainAxisAlignment.center,
                child: Center(
                  child: Card(
                    child: Column(
                      
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ListTile(
                          title: Text('Updating your preferences'),
                          subtitle: Text('This should only take a moment'),
                        ),
                        CircularProgressIndicator(strokeWidth: 10,),
                        ListTile(),
                        
                      ],
                    )
                  )
                )
            );
            print('start');
            await updatePreferences(context);
            print('end');
            Navigator.pop(context);
            Navigator.pop(context);
          }),
    );
  }

  Widget _interestList() {
    DataContainerState data = DataContainer.of(context);
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
                data.getCategoryRatings()[_categories[i]] = value;
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
