
import 'utility.dart';

class DataContainer {
  List<Attraction> _currentAttractions = [];
  List<Attraction> _favourites = [];
  Map _categoryRatings;

  DataContainer(){
    // udskiftes med API kald
    _currentAttractions = [];     /*new Attraction(
        'Tower of London',
        '8:00 - 17:30',
        'https://i.imgur.com/ZBAHIe0.jpg',
        false,
        4.8,
        'A tower in London',
        'https://www.hrp.org.uk/tower-of-london/',
        51.508144,
        -0.07626),
    new Attraction(
        'Tower of London 2',
        '8:00 - 17:30',
        'ToL.png',
        false,
        4.8,
        'A tower in London',
        'https://www.hrp.org.uk/tower-of-london/',
        51.528144,
        -0.04626),
    new Attraction(
        'Tower of London 3',
        '8:00 - 17:30',
        'ToL.png',
        false,
        4.8,
        'A tower in London',
        'https://www.hrp.org.uk/tower-of-london/',
        51.508144,
        -0.06326),
    new Attraction(
        'Tower of London 4',
        '8:00 - 17:30',
        'ToL.png',
        false,
        4.8,
        'A tower in London',
        'https://www.hrp.org.uk/tower-of-london/',
        51.538144,
        -0.05626),
    new Attraction(
        'Tower of London 5',
        '8:00 - 17:30',
        'ToL.png',
        false,
        4.8,
        'A tower in London',
        'https://www.hrp.org.uk/tower-of-london/',
        51.548144,
        -0.06626),
    new Attraction(
        'Mc Donald\'s',
        '0:00 - 24:00',
        'mcd.png',
        false,
        3.8,
        'Family restaurant',
        'https://www.mcdonalds.com/',
        37.4222,
        -122.0758),
    new Attraction(
        'Mc Donald\'s 2',
        '0:00 - 24:00',
        'mcd.png',
        false,
        3.9,
        'Family restaurant',
        'https://www.mcdonalds.com/',
        37.4242,
        -122.0778),
        new Attraction(
        'Mc Donald\'s',
        '0:00 - 24:00',
        'mcd.png',
        true,
        3.8,
        'Family restaurant',
        'https://www.mcdonalds.com/',
        37.4242,
        -122.0808),
    new Attraction(
        'Mc Donald\'s 2',
        '0:00 - 24:00',
        'mcd.png',
        true,
        3.9,
        'Family restaurant',
        'https://www.mcdonalds.com/',
        37.4242,
        -122.0808),
    new Attraction(
      'Mc Donald\'s 3',
      '0:00 - 24:00',
      'mcd.png',
      true,
      3.2,
      'Family restaurant',
      'https://www.mcdonalds.com/',
      37.4142,
      -122.0858,
    ),
    new Attraction(
        'Mc Donald\'s 4',
        '0:00 - 24:00',
        'mcd.png',
        true,
        3.3,
        'Family restaurant',
        'https://www.mcdonalds.com/',
        37.4212,
        -122.0808),
    new Attraction(
        'Mc Donald\'s 5',
        '0:00 - 24:00',
        'mcd.png',
        true,
        4.2,
        'Family restaurant',
        'https://www.mcdonalds.com/',
        37.4248,
        -122.0908),];*/
    _favourites = [];
    _categoryRatings = Map.fromIterables(['pref_0','pref_1','pref_2','pref_3','pref_4', 'pref_5', 'pref_6'], [0,0,0,0,0,0,0]);
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