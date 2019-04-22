import 'package:flutter/material.dart';

class Settings extends State<SettingsState> {
  int _n = 0;
  String dropdownValue = 'Solo';

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
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            //margin: EdgeInsets.symmetric(vertical: 6.0),
            constraints: BoxConstraints(maxWidth: width),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SizedBox(
                  width: width / 2,
                  child: Text(
                      'Max recommendation distance hvad hvis vi skriver meget her'),
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
          Divider(),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            //margin: EdgeInsets.symmetric(vertical: 6.0),
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
          Divider(),
          ListTile(
            title: Text('Change your category ratings'),
            trailing: Icon(Icons.arrow_right),
            //onTap: naviger til select_interests,
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
