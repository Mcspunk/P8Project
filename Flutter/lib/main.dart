import 'package:flutter/material.dart';
import 'select_interests.dart';
import 'settings.dart';
import 'sign_in.dart';
import 'home_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:isolate';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_helper.dart';


FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

Future printHello() {
  final DateTime now = DateTime.now();
  singlePOINotif(flutterLocalNotificationsPlugin, title: 'Title', body: 'Body');  
  print("[$now] Hello, world!");
}

main() async {
  final int helloAlarmID = 0;
  var initializationSettingsAndroid = new AndroidInitializationSettings('app_icon');
  var initializationSettingsIOS = new IOSInitializationSettings(onDidReceiveLocalNotification: onDidRecieveLocationLocation);
  var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);  
  flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: onSelectNotification);

  await AndroidAlarmManager.initialize();
  runApp(MyApp());
  await AndroidAlarmManager.periodic(const Duration(minutes: 2), helloAlarmID, printHello);
}

//TODO IOS specific navigation
  Future onDidRecieveLocationLocation(int id, String title, String body, String payload) {
     
  }
        
  //Ikke sikker på at denne navigation er korrekt
  Future onSelectNotification(String payload) {
    MaterialPageRoute(builder: (context) => HomeScreenState());
  }


//void main() => runApp(MyApp());


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
