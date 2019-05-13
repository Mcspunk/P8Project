import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'data_provider.dart';
import 'data_container.dart';
import 'utility.dart';

void clearSharedPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.clear();
}

class Settings extends State<SettingsState> {
  int _n =  1;
  String dropdownValue = 'Solo';
  bool createRecAttOnly = true;

  @override
  void initState() {
    loadInt('dist').then(loadDistance);
    loadString('tripType').then(loadTripType);
    loadBool('createRecAttOnly').then(loadcreateRecAttOnly);
    //clearSharedPrefs();
    super.initState();
  }

  void loadTripType(String tripType) {
    setState(() {
      this.dropdownValue = tripType ?? 'Solo';
    });
  }

  loadcreateRecAttOnly(bool onlyRec){
    setState(() {
      this.createRecAttOnly = onlyRec ?? false;
    });
  }

  void loadDistance(int distance) {
    setState(() {
      this._n = distance ?? 1;
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
    DataContainer data = DataProvider.of(context).dataContainer;
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
      body: WillPopScope(
        onWillPop: (){
          data.setDist(_n);
          saveInt('dist', _n);
          data.setTripType(dropdownValue);
          saveString('tripType', dropdownValue);
          data.setcreateRecAttOnly(createRecAttOnly);
          saveBool('createRecAttOnly', createRecAttOnly);

          print('saved');
          return new Future.value(true);
        },
        child:_customSettings(),
      )
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
            trailing: Icon(Icons.border_color),
            onTap: () {
              Navigator.pushNamed(context, '/select_interests');
            },
          ),
          Divider(),
          SwitchListTile(
            title: Text('Show only recommended attractions'),
            value: createRecAttOnly,

            onChanged: (value) {
              createRecAttOnly = !createRecAttOnly;
            }
          ),
          Divider(),
          ListTile(
            title: Text('Delete local data'),
            trailing: Icon(Icons.warning),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Delete local data?'),
                    content: Text('This will remove all data from your device such as rating information, favorite places, login information etc.'),
                    actions: <Widget>[
                      FlatButton(
                        child: const Text('Delete'),
                        onPressed: () {
                          clearSharedPrefs();
                          Navigator.pushNamedAndRemoveUntil(context, '/LogIn', (Route<dynamic> route) => false);
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
                    title: Text('Are you sure you want to log out?'),
                    actions: <Widget>[
                      FlatButton(
                        child: const Text('Log out'),
                        onPressed: () {
                          deleteString('currentUser');
                          Navigator.pushNamedAndRemoveUntil(context, '/LogIn', (Route<dynamic> route) => false);
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
        ],
      ),
    );
  }

  void decrement() {
    setState(() {
      if (_n != 1) _n--;
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
