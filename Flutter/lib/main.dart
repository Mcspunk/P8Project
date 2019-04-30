import 'package:flutter/material.dart';
import 'select_interests.dart';
import 'settings.dart';
import 'sign_in.dart';
import 'home_screen.dart';

void main() => runApp(MyApp());



class MyApp extends StatelessWidget {
  bool loggedIn = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign in',
      theme: new ThemeData(
        primaryColor: Colors.lightBlue,
      ),
      home: HomeScreenState(),
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => HomeScreenState());
            break;
          case '/LogIn':
            return MaterialPageRoute(builder: (context) => LogInState());
            break;
          case '/settings':
            return MaterialPageRoute(builder: (context) => SettingsState());
            break;
          case '/select_interests':
            return MaterialPageRoute(builder: (context) => InterestsState());
            break;
          
        }
      },
    );
  }
}
