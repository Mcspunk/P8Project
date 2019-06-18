import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'data_provider.dart';

import 'utility.dart';

class DataContainerState extends State<DataContainer> {
  List<Attraction> _currentAttractions = [];
  List<Attraction> _favourites = [];
  List<Attraction> _allNearbyAttractions = [];
  List<Marker> _markers = [];
  int _dist = 1;
  String _triptype = 'Solo';
  Map _categoryRatings;
  bool _createRecAttOnly = true;
  bool _updateRecs = false;
  bool _distPenEnabled = true;
  ThemeData _theme = jdLightTheme();

  DataContainerState() {
    _categoryRatings = Map.fromIterables([
      'Museums',
      'Art Museums',
      'Sights & Landmarks',      
      'Points of Interest & Landmarks',
      'Historic Sites',
      'Concerts & Shows',
      'Theaters',
      'Nature & Parks',
      'Churches & Cathedrals',
      'Gardens',
      'Cafe',
      'Seafood',
      'Steakhouse',
      'Indian',
      'British',
      'Mediterranean',
      'French',
      'Italian',
      'European'
    ], [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    ]);
  }

  List<Attraction> getAttractions() => _currentAttractions;

  void setDistPenEnabled(val) {
    _distPenEnabled = val;
  }

  bool getDistPenEnabled() {
    return _distPenEnabled;
  }

  void setAttractions(attractions) {
    _currentAttractions = attractions;
  }

  List<Attraction> getFavourites() => _favourites;

  void setFavourites(favouriteAttractions) {
    _favourites = favouriteAttractions;
  }

  List<Marker> getMarkers() => _markers;

  void setMarkers(markers) {
    _markers = markers;
  }

  int getDist() => _dist;

  void setDist(distance) {
    _dist = distance;
  }


  List<Attraction> getAllNearbyAttractions() => _allNearbyAttractions;

  void setAllNearbyAttractions(nearbyAttractions) {
    _allNearbyAttractions = nearbyAttractions;
  }

  Map getCategoryRatings() => _categoryRatings;

  String getTripType() => _triptype;

  void setTripType(tripType) {
    _triptype = tripType;
  }

  bool getcreateRecAttOnly() => _createRecAttOnly;

  void setcreateRecAttOnly(bool createRecAttOnly) {
    _createRecAttOnly = createRecAttOnly;
  }

  ThemeData getTheme() => _theme;

  void setTheme(theme){
    _theme = theme;
  }

  @override
  Widget build(BuildContext context) {
    return new DataProvider(dataContainer: this, child: widget.child);
  }
}

class DataContainer extends StatefulWidget {
  Widget child;

  DataContainer({this.child});

  @override
  DataContainerState createState() => new DataContainerState();

  static DataContainerState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(DataProvider) as DataProvider)
        .dataContainer;
  }
}
