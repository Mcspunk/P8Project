import 'package:flutter/material.dart';
import 'select_interests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'data_provider.dart';
import 'data_container.dart';
import 'utility.dart';

void clearSharedPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.clear();
}

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
/*
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    DataContainer data = DataProvider.of(context).dataContainer;
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text('Settings  '),
            Icon(Icons.settings),
          ],
        )
        
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
            title: Text('Change your category ratings'),
            trailing: Icon(Icons.arrow_right),
            onTap: () {
              saveDistance('dist', _n);
              saveTripType('tripType', dropdownValue);
              Navigator.pushNamed(context, '/select_interests');
            },
          ),
          Divider(),
          ListTile(
            title: Text('Delete all data'),
            trailing: Icon(Icons.warning),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Delete app data?'),
                    content: Text('This will remove all data from your device such as rating information, favorite places, login information etc.'),
                    actions: <Widget>[
                      FlatButton(
                        child: const Text('Delete'),
                        onPressed: () {
                          clearSharedPrefs();
                          Navigator.of(context).pop();
                          
                          //Her skal vi måske gå til loginscreen TODO
                        },
                      ),
                      FlatButton(
                        child: const Text('Cancel'),
                        onPressed: (){Navigator.of(context).pop();},
                      ),
                    ],
                  );
                }
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Log out'),
            trailing: Icon(Icons.exit_to_app),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Really log out?'),
                    actions: <Widget>[
                      FlatButton(
                        child: const Text('Log out'),
                        onPressed: () {
                          deleteString('currentUser');
                          Navigator.of(context).pop();
                          
                          //Her skal vi måske gå til loginscreen TODO
                        },
                      ),
                      FlatButton(
                        child: const Text('Cancel'),
                        onPressed: (){Navigator.of(context).pop();},
                      ),
                    ],
                  );
                }
              );
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
