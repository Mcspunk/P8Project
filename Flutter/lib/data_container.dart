
import 'package:flutter_map/flutter_map.dart';

import 'utility.dart';

class DataContainer {
  List<Attraction> _currentAttractions = [];
  List<Attraction> _favourites = [];
  List<Attraction> _allNearbyAttractions = [];
  List<Marker> _markers = [];
  int _dist = 1;
  String _triptype = 'Solo';
  Map _categoryRatings;
  bool _createRecAttOnly = true;


  DataContainer(){
    _categoryRatings = Map.fromIterables(['Museum', 'Parks', 'Ferris Wheel'], [0,0,0]);
  }

  List<Attraction> getAttractions() => _currentAttractions;

  void setAttractions(attractions){
    _currentAttractions = attractions;
  }

  List<Attraction> getFavourites() => _favourites;

  void setFavourites(favouriteAttractions){
    _favourites = favouriteAttractions;
  }

  List<Marker> getMarkers() => _markers;

  void setMarkers(markers){
    _markers = markers;
  }

  int getDist() => _dist;

  void setDist(distance){
    _dist = distance;
  }

  List<Attraction> getAllNearbyAttractions() => _allNearbyAttractions;

  void setAllNearbyAttractions(nearbyAttractions){
    _allNearbyAttractions = nearbyAttractions;
  }

  Map getCategoryRatings() => _categoryRatings;

  String getTripType() => _triptype;

  void setTripType(tripType){
    _triptype = tripType;
  }

  bool getcreateRecAttOnly() => _createRecAttOnly;

  void setcreateRecAttOnly(bool createRecAttOnly){
    _createRecAttOnly = createRecAttOnly;
  }
}