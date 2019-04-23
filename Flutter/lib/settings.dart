import 'package:flutter/material.dart';
import 'select_interests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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

class Settings extends State<SettingsState> {
  int _n = 0;
  String dropdownValue = 'Solo';

  @override
  void initState() {
    getDistance('dist').then(loadDistance);
    getTripType('tripType').then(loadTripType);
    super.initState();
  }

  void loadTripType(String tripType) {
    setState(() {
      this.dropdownValue = tripType;
    });
  }

  void loadDistance(int distance) {
    setState(() {
      this._n = distance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Settings')),
        backgroundColor: Colors.grey,
      ),
      body: _customSettings(),
      //primary: false,
    );
  }

  Widget _customSettings() {
    double width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width,
      child: ListView(
        children: <Widget>[
          Divider(),
          ListTile(
            //padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            //margin: EdgeInsets.symmetric(vertical: 6.0),

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
                              color: Colors.black,
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
                            color: Colors.black,
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
            title: Text('Change your category ratings'),
            trailing: Icon(Icons.arrow_right),
            onTap: () {
              saveDistance('dist', _n);
              saveTripType('tripType', dropdownValue);
              Navigator.pushNamed(context, '/select_interests');
            },
          ),
          Divider(),
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

class SettingsState extends StatefulWidget {
  @override
  Settings createState() => Settings();
}
