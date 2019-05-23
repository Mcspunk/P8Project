import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dart:async';



  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  void initPushNotif() async { 
    //Initialize push notification settings
    var initializationSettingsAndroid = new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings(onDidReceiveLocalNotification: onDidRecieveLocalNotification);
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);  
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: onSelectNotification);
  }

    //TODO IOS specific navigation
  Future onDidRecieveLocalNotification(int id, String title, String body, String payload) {
    
  }
          
  //Ikke sikker på at denne navigation er korrekt
  Future onSelectNotification(String payload) {
    MaterialPageRoute(builder: (context) => HomeScreenState());
  }


// Notification types ---------------------------------------------------

  NotificationDetails get _singlePOI {
    final androidChannelSpecifics = AndroidNotificationDetails(
      'channelId', 
      'channelName', 
      'channelDescription',
      ongoing: true,
      importance: Importance.Max,
      priority: Priority.High,
      autoCancel: false,      
    );
    final iOSChannelSpecificss = IOSNotificationDetails();
    return NotificationDetails(androidChannelSpecifics, iOSChannelSpecificss);
  }


  //Notification methods --------------------------------------------------

  //Method to display new POI 
  Future singlePOINotif (
    FlutterLocalNotificationsPlugin notification, {
      @required String title,
      @required String body,
      int id = 0,
    }) => _showNotification(notification, id: id, title: title, body: body, type: _singlePOI);

  // general method to show notifications
  Future _showNotification(    
    FlutterLocalNotificationsPlugin notification, {
      @required String title,
      @required String body,
      @required NotificationDetails type,
      int id,
    }) => notification.show(id,title,body,type);