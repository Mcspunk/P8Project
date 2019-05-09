import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'notification_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'home_screen.dart';
import 'dart:async';
import 'utility.dart';



  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  double _distanceLimit = 0; //meters
  Geolocator _geolocator = Geolocator()..forceAndroidLocationManager = true;

  void getUserLocationAndGPSPermissionAndInitPushNotif() async {

  //  Position position = await _geolocator.getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

    //Initialize push notification settings
    var initializationSettingsAndroid = new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings(onDidReceiveLocalNotification: onDidRecieveLocationLocation);
    var initializationSettings = new InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);  
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: onSelectNotification);
  }

  Future<bool> checkLocationStatus() async {  
    GeolocationStatus geolocationStatusA = await Geolocator().checkGeolocationPermissionStatus(locationPermission: GeolocationPermission.locationAlways);
    GeolocationStatus geolocationStatusW = await Geolocator().checkGeolocationPermissionStatus(locationPermission: GeolocationPermission.locationWhenInUse);
    
    if (geolocationStatusA == GeolocationStatus.granted && geolocationStatusW == GeolocationStatus.granted ) {
      return true;
    }
    return false; 
  }

  void locationChecker() async {
    double distanceInMeters;
    Position _currentUserLocation;
    
    if (await checkLocationStatus() == true) {
      _currentUserLocation = await _geolocator.getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

      if (await loadString('latestUserLocationlat') == null) {
        saveString('latestUserLocationLat', _currentUserLocation.latitude.toString());
        saveString('latestUserLocationLong', _currentUserLocation.longitude.toString());
      }        

      if (_currentUserLocation == null) {
        //Either user has not given permission or cant get GPS signal
      }
      else {
        distanceInMeters = await Geolocator().distanceBetween(double.parse(await loadString('latestUserLocationLat')), double.parse(await loadString('latestUserLocationLong')), _currentUserLocation.latitude, _currentUserLocation.longitude);
       
        //print('Debug printing:');
        //print('Old:   lat: ' + await loadString('latestUserLocationLat') + ' long: ' +  await loadString('latestUserLocationLong'));
        //print('Curr:  lat: ' + _currentUserLocation.latitude.toString() + ' long: ' +  _currentUserLocation.longitude.toString());      
        //print('Distance in meters: ' + distanceInMeters.toString());
      }
    }

    if (distanceInMeters == _distanceLimit) {
      saveString('latestUserLocationLat', _currentUserLocation.latitude.toString());
      saveString('latestUserLocationLong', _currentUserLocation.longitude.toString());
      //int a = 3; // await API_CALL
      int a = await getRecCount(new Coordinate(_currentUserLocation.latitude, _currentUserLocation.longitude));
      if (a > 0) {
        singlePOINotif(flutterLocalNotificationsPlugin, title: a.toString() + ' New sights to discover!', body: 'We have found ' + a.toString() + ' new places that we think you might be interested in! Check them out in the app.');  
      }
    }  
  }

  //TODO IOS specific navigation
  Future onDidRecieveLocationLocation(int id, String title, String body, String payload) {
    MaterialPageRoute(builder: (context) => HomeScreenState());
  }
          
  //Ikke sikker på at denne navigation er korrekt
  Future onSelectNotification(String payload) {
    MaterialPageRoute(builder: (context) => HomeScreenState());
  }
