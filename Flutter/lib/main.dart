import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'select_interests.dart';
import 'settings.dart';
import 'sign_in.dart';
import 'home_screen.dart';
import 'data_provider.dart';
import 'data_container.dart';
import 'notification_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'dart:async';
import 'location_manager.dart';
import 'utility.dart';
import 'context_prompt.dart';

//AndroidAlarmManager aAM = new AndroidAlarmManager();

main() async {
  final int helloAlarmID = 0;
  //await AndroidAlarmManager.initialize();
  runApp(MyApp());
  getUserLocationAndGPSPermissionAndInitPushNotif();
  //await AndroidAlarmManager.periodic(const Duration(seconds: 60), helloAlarmID, locationChecker);
}
//void main() => runApp(MyApp());

class MyApp extends StatelessWidget {  
  bool loggedIn = false;

  static Widget determineHome(){
    if (loadString('currentUser') == null){
      return LogInState();
    }
    else{
      return HomeScreenState();
    }
  }
  
  @override
  Widget build(BuildContext context) {    
    return DataProvider(
      dataContainer: DataContainer(),
      child: MaterialApp(
        title: 'Sign in',
        theme: utilTheme(),
        home: determineHome(),
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
            case '/context_prompt':
              return MaterialPageRoute(builder: (context) => PromptContextState());
              break;
          }
        },
      ),
    );
  }
}
