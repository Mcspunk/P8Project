
import 'utility.dart';

class DataContainer {
  List<Attraction> _currentAttractions = [];
  List<Attraction> _favourites = [];
  Map _categoryRatings;

  DataContainer(){
    // udskiftes med API kald
    _currentAttractions = [Attraction('sted', 'openingHours', 'imgPath', true), Attraction('sted2', 'openingHours2', 'imgPath2', true)];
    _favourites = [Attraction('sted2', 'openingHours2', 'imgPath2', true)];
    _categoryRatings = Map.fromIterables(['1','2','3','4','5'], [1,2,3,4,5]);
    
  }

  List<Attraction> getAttractions() => _currentAttractions;

  void setAttractions(attractions){
    _currentAttractions = attractions;
  }

  List<Attraction> getFavourites() => _favourites;

  void setFavourites(favouriteAttractions){
    _favourites = favouriteAttractions;
  }

  Map getCategoryRatings() => _categoryRatings;

}