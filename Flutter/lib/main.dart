import 'package:flutter/material.dart';
import 'select_interests.dart';
import 'settings.dart';
import 'sign_in.dart';
import 'home_screen.dart';
import 'data_provider.dart';
import 'data_container.dart';
import 'notification_helper.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'location_manager.dart';
import 'utility.dart';
import 'dart:io' show Platform;
import 'package:background_fetch/background_fetch.dart';
import 'package:permission_handler/permission_handler.dart';
import 'context_prompt.dart';
//import 'package:permission_handler/permission_handler.dart';

//AndroidAlarmManager aAM = new AndroidAlarmManager();

main() async {
  final int helloAlarmID = 0;
  if (Platform.isAndroid) {
    await AndroidAlarmManager.initialize();
    runApp(MyApp());
    await PermissionHandler().checkPermissionStatus(PermissionGroup.location);
    initPushNotif();
    Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.location]);
    await AndroidAlarmManager.periodic(const Duration(minutes: 1), helloAlarmID, locationChecker);    
 
  }
  else {
    runApp(MyApp());
    initPushNotif();
   // BackgroundFetch.registerHeadlessTask(locationChecker);
  }
}

void bgfFired() {
  DateTime a = new DateTime.now();
  print(a.toString() + ' backgroundFetch fired-------------------------------------');
  BackgroundFetch.finish();
}

//void main() => runApp(MyApp());

class MyApp extends StatelessWidget {  
  static Widget determineHome() {
    if (loadString('currentUser') == null) {
      return LogInState();
    } else {
      return HomeScreenState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataProvider(
      dataContainer: DataContainerState(),
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
