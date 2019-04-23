import 'package:flutter/material.dart';
import 'select_interests.dart';
import 'settings.dart';
import 'sign_in.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign in',
      theme: new ThemeData(
        primaryColor: Colors.lightBlue,
      ),
      home: SettingsState(),
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => SettingsState());
            break;
          case '/select_interests':
            return MaterialPageRoute(builder: (context) => InterestsState());
        }
      },
    );
  }
}
