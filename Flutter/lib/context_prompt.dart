import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:test2/data_container.dart';


void saveDistance(String key, int value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt(key, value);
}

Future<int> getDistance(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt(key);
}

void saveTripType(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(key, value);
}

Future<String> getTripType(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

class PromptContextState extends StatefulWidget {
  @override
  PromptContext createState() => PromptContext();
}

class PromptContext extends State<PromptContextState>{
  
   int _n = 0;
  String dropdownValue = 'Solo';

  @override
  void initState() {
    getDistance('dist').then(loadDistance);
    getTripType('tripType').then(loadTripType);
    //clearSharedPrefs();
    super.initState();
  }

  void loadTripType(String tripType) {
    setState(() {
      this.dropdownValue = tripType ?? 'Solo';
    });
  }

  void loadDistance(int distance) {
    setState(() {
      this._n = distance ?? 0;
    });
  }

  @override Widget build(BuildContext context) {
    DataContainerState data = DataContainer.of(context);
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: Text('Initial information'),),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Enter your context. This can also be changed later in settings.'),
          ),
          Divider(),
          ListTile(
            title: Container(
              constraints: BoxConstraints(maxWidth: width),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    width: width / 2,
                    child: Text('Max recommendation distance (km)'),
                  ),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: width / 10,
                        child: FlatButton(
                          onPressed: decrement,
                          child: Center(
                            child: Icon(
                              Icons.arrow_left,
                            ),
                          ),
                        ),
                      ),
                      Text('$_n'),
                      SizedBox(
                        width: width / 10,
                        child: FlatButton(
                          onPressed: increment,
                          child: Icon(
                            Icons.arrow_right,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Divider(),
          ListTile(
            title: Container(
              constraints: BoxConstraints(maxWidth: width),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    width: width / 2,
                    child: Text('How are you traveling'),
                  ),
                  DropdownButton<String>(
                    value: dropdownValue,
                    onChanged: (String newValue) {
                      setState(() {
                        dropdownValue = newValue;
                      });
                    },
                    items: <String>['Solo', 'Couple', 'Family', 'Business']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Divider(),
          ListTile(
            title: MaterialButton(
              color: data.getTheme().accentColor,
              child: Text('Continue'),
              onPressed: () {
                saveDistance('dist', _n);
                saveTripType('tripType', dropdownValue);
                Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
                Navigator.pushNamed(context, '/select_interests');
              },
            ),
          ),
        ],
      ),
    );
  }
    void decrement() {
    setState(() {
      if (_n != 0) _n--;
    });
  }

  void increment() {
    setState(() {
      if (_n != 9) _n++;
    });
  }
}