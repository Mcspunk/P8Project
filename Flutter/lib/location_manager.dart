import 'package:geolocator/geolocator.dart';
import 'notification_helper.dart';
import 'utility.dart';
import 'package:permission_handler/permission_handler.dart';



  
  int _distanceLimit = 1000; //meters
  Geolocator _geolocator = Geolocator()..forceAndroidLocationManager = true;

  void locationChecker() async {
    double distanceInMeters;
    Position _currentUserLocation;
    
    if (await PermissionHandler().checkPermissionStatus(PermissionGroup.location) == PermissionStatus.granted) {
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
        _distanceLimit = (await loadInt('dist')) * 1000;
        //print('Debug printing:');
        //print('Old:   lat: ' + await loadString('latestUserLocationLat') + ' long: ' +  await loadString('latestUserLocationLong'));
        //print('Curr:  lat: ' + _currentUserLocation.latitude.toString() + ' long: ' +  _currentUserLocation.longitude.toString());      
        //print('Distance in meters: ' + distanceInMeters.toString());
      }
    }
    else {
      print('No permission');
    }

    if (distanceInMeters > _distanceLimit) {
      saveString('latestUserLocationLat', _currentUserLocation.latitude.toString());
      saveString('latestUserLocationLong', _currentUserLocation.longitude.toString());
      //int a = 3; // await API_CALL
      int a = await getRecCount(new Coordinate(_currentUserLocation.latitude, _currentUserLocation.longitude));
      if (a > 0) {
        singlePOINotif(flutterLocalNotificationsPlugin, title: a.toString() + ' New sights to discover!', body: 'We have found ' + a.toString() + ' new places that we think you might be interested in! Check them out in the app.');  
      }
    } 
    else {
      print('Distance from prev location not larger than distance limit');
    } 
  }

