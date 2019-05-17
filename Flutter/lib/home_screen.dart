import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'package:test2/data_container.dart';
import 'utility.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'sign_in.dart';
import 'dart:async';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'data_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RatingDialog extends State<RatingState> {
  //https://www.youtube.com/watch?v=MsycCv5r2Wo
  double attractionRating = 0;
  String tripType = '';
  String dateText = 'Select date';

  @override
  Widget build(BuildContext context) {
    DataContainerState data = DataContainer.of(context);
    tripType = data.getTripType();

    void setDateText(String date) {
      setState(() {
        dateText = date;
      });
    }

    DateTime selectedTime = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate ' + widget.attraction.getName()),
      ),
      body: ListView(
        children: <Widget>[
          Container(
              constraints: BoxConstraints.expand(
                height: 200.0,
              ),
              alignment: Alignment.bottomLeft,
              padding: EdgeInsets.only(left: 4.0, bottom: 2.0),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.attraction.getImgPath()),
                  fit: BoxFit.cover,
                ),
              ),
              child: ListTile(
                title: Text(widget.attraction.getName(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                      color: Colors.white,
                      shadows: [
                        Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                        Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                        Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                        Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                      ],
                    )),
              )),
          ListTile(
            title: Text('Your rating'),
            trailing: SmoothStarRating(
                rating: attractionRating,
                size: 25,
                starCount: 5,
                color: Colors.orange[400],
                borderColor: Colors.grey,
                onRatingChanged: (value) {
                  setState(() {
                    attractionRating = value;
                  });
                }),
          ),
          Divider(),
          ListTile(
            title: Text('How were you traveling when visiting?'),
            trailing: DropdownButton<String>(
              value: tripType,
              onChanged: (String newValue) {
                setState(() {
                  tripType = newValue;
                  data.setTripType(tripType);
                });
              },
              items: <String>['Solo', 'Couple', 'Family', 'Business']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Divider(),
          ListTile(
              title: Text('When did you visit?'),
              trailing: RaisedButton(
                child: Text(dateText),
                color: Theme.of(context).accentColor,
                onPressed: () async {
                  Future<DateTime> chosenTime = showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2018),
                    lastDate: DateTime(2030),
                    builder: (BuildContext context, Widget child) {
                      return Theme(
                        data: ThemeData.dark(),
                        child: child,
                      );
                    },
                  );
                  setState(() async {
                    selectedTime = await chosenTime;
                    setDateText(selectedTime.day.toString() +
                        '-' +
                        selectedTime.month.toString() +
                        '-' +
                        selectedTime.year.toString());
                  });
                },
              )),
          Divider(),
          ListTile(
            title: RaisedButton(
              child: Text('Submit review'),
              color: Theme.of(context).accentColor,
              onPressed: () {
                giveReview(attractionRating, selectedTime, tripType,
                    widget.attraction.getName(), context);
                /*
                saveString(widget.attraction.GetName() + '%Rating',
                    attractionRating.toString());
                saveString(
                    widget.attraction.GetName() + '%Date',
                    selectedTime.day.toString() +
                        '/' +
                        selectedTime.month.toString());
                saveString(widget.attraction.GetName() + '%TripType', tripType);
                */
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RatingState extends StatefulWidget {
  final Attraction attraction;

  RatingState({Key key, this.attraction}) : super(key: key);

  @override
  RatingDialog createState() => RatingDialog();
}

class HomeScreen extends State<HomeScreenState> {
  double attractionRating = 0;
  Coordinate userLocation;
  bool distPenEnabled = true;
  int maxDist;
  String username;

  bool checkRefresh(bool val) {
    setState(() {
      this.distPenEnabled = val ?? false;
    });
  }

  void refreshDistancePenalty() {
    DataContainerState data = DataContainer.of(context);
    bool wantsdistpen = data.getDistPenEnabled();
    List<Attraction> attractionList =
        List<Attraction>.from(data.getAttractions() ?? List<Attraction>());
    if (wantsdistpen) {
      for (var attraction in attractionList) {
        double score = attraction.getScore();
        double distPen =
            (5 / ((data.getDist() ?? 1) * 1000)) * (1000 + attraction.getDistance());
        double weight = calcWeight(score);
        double penalisedScore = score - (weight * distPen);
        attraction.setPenalisedScore(penalisedScore);
      }
    } else {
      for (var attraction in attractionList) {
        attraction.setPenalisedScore(attraction.getScore());
      }
    }
    attractionList
        .sort((a, b) => b.getPenalisedScore().compareTo(a.getPenalisedScore()));
    data.setAttractions(attractionList);
    setState(() {});
  }

  double calcWeight(double score) {
    return (-0.1 * score) + 0.7;
  }

  Widget _homeScreen() {
    DataContainerState data = DataContainer.of(context);
    return MaterialApp(
      theme: utilTheme(),
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Home'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: distPenEnabled ? refreshDistancePenalty : refreshDistancePenalty,
              ),              
              IconButton(
                  //Tror ikke det er her den her funktionalitet skal være, men kunne ikke få lov til at lave en tab mere
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    updateUserLocation();

                    userLocation == null
                        ? displayMsg(
                            'This feature requires access to your current location. Either you have not given us permission to use you location, or you location is currently not available.',
                            context)
                        : _fullMapView(data
                            .getAttractions()); // Det her skal være en liste af alle attractions inden for en radius
                  }),
              IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  }),
              /*
              new IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    setState(() {
                      //getRecommendations(new Coordinate(0.0,0.0), context);
                      //updatePreferences(context);
                      //getPreferences(context);
                      //updatePreferences(context);
                      //displayMsg(zoomLevel(distanceBetweenCoordinates(data.getAttractions()[0].GetCoordinate(), userLocation)).toStringAsFixed(2) , context);
                      getLikedAttraction(context);
                    });
                  }),
                */
            ],
            bottom: TabBar(tabs: [
              Tab(
                icon: Icon(Icons.home),
              ),
              Tab(
                icon: Icon(Icons.account_balance),
              ),
              Tab(
                icon: Icon(Icons.fastfood),
              ),
              Tab(
                icon: Icon(Icons.favorite),
              ),
            ]),
          ),
          body: TabBarView(
            children: [
              _allView(),
              _attractionView(),
              _restaurantView(),
              _likeView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecList(List<Attraction> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(1.0),
      itemBuilder: (context, i) {
        if (i.isOdd) {
          return Divider();
        }
        final index = i ~/ 2;

        if (index < items.length) {
          return buildInteractiveRecTile(items[index]);
        }
      },
    );
  }

  Widget _attractionView() {
    List<Attraction> data =
        DataContainer.of(context).getAttractions() ?? List<Attraction>();
    List<Attraction> attractions = [];
    for (var attraction in data) {
      if (!attraction.getIsFoodPlace()) {
        attractions.add(attraction);
      }
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: attractions.length != 0
          ? _buildRecList(attractions)
          : ListTile(
              title: Text('No attractions found'),
              subtitle: Text(
                  'Try going to a different area, or adjust your settings, in order to find some nearby attractions'),
              trailing: Icon(Icons.info_outline),
            ),
    );
  }

  Widget _allView() {
    DataContainerState data = DataContainer.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: data.getAttractions() != null && data.getAttractions().length != 0
          ? _buildRecList(data.getAttractions())
          : ListTile(
              title: Text('No attractions found'),
              subtitle: Text(
                  'Try going to a different area, or adjust your settings, in order to find some nearby attractions'),
              trailing: Icon(Icons.info_outline),
            ),
    );
  }

  Widget _restaurantView() {
    List<Attraction> data =
        DataContainer.of(context).getAttractions() ?? List<Attraction>();
    List<Attraction> restaurants = [];
    for (var attraction in data) {
      if (attraction.getIsFoodPlace()) {
        restaurants.add(attraction);
      }
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: restaurants.length != 0
          ? _buildRecList(restaurants)
          : ListTile(
              title: Text('No restaurants found'),
              subtitle: Text(
                  'Try going to a different area, or adjust your settings, in order to find some nearby restaurants'),
              trailing: Icon(Icons.info_outline),
            ),
    );
  }

  Widget _likeView() {
    DataContainerState data = DataContainer.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: data.getFavourites() != null && data.getFavourites().length != 0
          ? _buildRecList(data.getFavourites())
          : ListTile(
              title: Text('No liked attractions'),
              subtitle: Text(
                  'Tap the heart icon on the attractions to save them to your list of liked attractions'),
              trailing: Icon(Icons.info_outline),
            ),
    );
  }

  Widget buildRecCardTile(Attraction attraction) {
    final deviceSize = MediaQuery.of(context).size;
    DateTime dt = DateTime.now();
    return GestureDetector(
      onTap: () {
        _detailedAttractionView(attraction);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              constraints: BoxConstraints.expand(
                  height: deviceSize.height * 0.3,
                  width: deviceSize.width * 0.85),
              alignment: Alignment.bottomLeft,
              padding: EdgeInsets.only(left: 4.0, bottom: 2.0),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(attraction.getImgPath()),
                  fit: BoxFit.cover,
                ),
              ),
              child: ListTile(
                  title: Text(attraction.getName(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              offset: Offset(-1.5, -1.5), color: Colors.black),
                          Shadow(
                              offset: Offset(1.5, -1.5), color: Colors.black),
                          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                          Shadow(
                              offset: Offset(-1.5, 1.5), color: Colors.black),
                        ],
                      )))),
          ListTile(
              title: Text('Rating: ' + attraction.getRating().toString()),
              trailing: Container(
                  width: deviceSize.width * (3 / 7),
                  child: Text(
                      "Opening hours:\n" +
                          attraction.getOpeningHours()[dt.weekday - 1],
                      style: Theme.of(context).textTheme.body2)))
        ],
      ),
    );
  }

  Widget buildRecTile(Attraction attraction) {
    var match;
    if (attraction.getPenalisedScore() != null) {
      match = attraction.getPenalisedScore() / 5 * 100;
    }

    DateTime dt = DateTime.now();
    String ratingstring =
        attraction.getPenalisedScore() == null || match == null
            ? 'Rating: ' + attraction.getRating().toStringAsFixed(2)
            : 'Match: ' +
                match.toStringAsFixed(2) +
                '%' +
                '\nRating: ' +
                attraction.getRating().toString();

    String distanceString = attraction.getDistance() != null
        ? 'Distance: ' +
            (attraction.getDistance() > 1000
                ? (attraction.getDistance() / 1000).toStringAsFixed(2)
                : attraction.getDistance().toStringAsFixed(0)) +
            (attraction.getDistance() > 1000 ? "km" : "m")
        : "";

    DataContainerState data = DataContainer.of(context);
    final deviceSize = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Theme.of(context).primaryColorDark,
        border: Border.all(
          color: Theme.of(context).hintColor,
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
              constraints:
                  BoxConstraints.expand(height: deviceSize.height * 0.3),
              alignment: Alignment.bottomLeft,
              padding: EdgeInsets.only(left: 4.0, bottom: 2.0),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(attraction.getImgPath()),
                  fit: BoxFit.cover,
                ),
              ),
              child: ListTile(
                  title: Text(attraction.getName(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              offset: Offset(-1.5, -1.5), color: Colors.black),
                          Shadow(
                              offset: Offset(1.5, -1.5), color: Colors.black),
                          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                          Shadow(
                              offset: Offset(-1.5, 1.5), color: Colors.black),
                        ],
                      )),
                  trailing: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (data.getFavourites().contains(attraction)) {
                            data.getFavourites().remove(attraction);
                            updateLikedAttraction(context);
                          } else {
                            data.getFavourites().add(attraction);
                            updateLikedAttraction(context);
                          }
                        });
                      },
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                            top: 1.0,
                            left: 1.0,
                            child: Icon(
                              Icons.favorite,
                              color: Colors.black,
                            ),
                          ),
                          Positioned(
                            top: -1.0,
                            left: 1.0,
                            child: Icon(
                              Icons.favorite,
                              color: Colors.black,
                            ),
                          ),
                          Positioned(
                            top: 1.0,
                            left: -1.0,
                            child: Icon(
                              Icons.favorite,
                              color: Colors.black,
                            ),
                          ),
                          Positioned(
                            top: -1.0,
                            left: -1.0,
                            child: Icon(
                              Icons.favorite,
                              color: Colors.black,
                            ),
                          ),
                          Icon(
                            Icons.favorite,
                            color: data.getFavourites().contains(attraction)
                                ? Colors.red
                                : Colors.white,
                          )
                        ],
                      )))),
          ListTile(
            title: Text(ratingstring),
            //leading: Text('Score: ' + attraction.getScore().toString()),
            subtitle: Text(distanceString),
            trailing: Container(
              width: deviceSize.width * (3 / 7),
              child: Text(
                  "Opening hours:\n" +
                      attraction.getOpeningHours()[dt.weekday - 1],
                  style: Theme.of(context).textTheme.body2),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInteractiveRecTile(Attraction attraction) {
    return GestureDetector(
        onTap: () {
          _detailedAttractionView(attraction);
        },
        child: buildRecTile(attraction));
  }

  void _detailedAttractionView(Attraction attraction) {
    final deviceSize = MediaQuery.of(context).size;
    Navigator.of(context)
        .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text(attraction.getName())),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            buildRecTile(attraction),
            Container(
              child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Padding(
                    padding: EdgeInsets.all(deviceSize.width * (1 / 28)),
                    child: Text('Phone Number: ',
                        style: Theme.of(context).textTheme.body2)),
                Padding(padding: EdgeInsets.all(deviceSize.width * (1 / 12))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                        (attraction.getPhoneNumber() != null
                            ? attraction.getPhoneNumber()
                            : 'N/A'),
                        style: Theme.of(context).textTheme.body2),
                  ],
                ),
              ]),
            ),
            Divider(),
            Container(
              height: deviceSize.height * (1 / 6),
              child: Row(children: [
                Padding(
                    padding: EdgeInsets.all(deviceSize.width * (1 / 28)),
                    child: Text('Weekly opening hours',
                        style: Theme.of(context).textTheme.body2)),
                Padding(padding: EdgeInsets.all(deviceSize.width * (1 / 24))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(attraction.getOpeningHours()[0],
                        style: Theme.of(context).textTheme.body2),
                    Text(attraction.getOpeningHours()[1],
                        style: Theme.of(context).textTheme.body2),
                    Text(attraction.getOpeningHours()[2],
                        style: Theme.of(context).textTheme.body2),
                    Text(attraction.getOpeningHours()[3],
                        style: Theme.of(context).textTheme.body2),
                    Text(attraction.getOpeningHours()[4],
                        style: Theme.of(context).textTheme.body2),
                    Text(attraction.getOpeningHours()[5],
                        style: Theme.of(context).textTheme.body2),
                    Text(attraction.getOpeningHours()[6],
                        style: Theme.of(context).textTheme.body2),
                  ],
                ),
              ]),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                MaterialButton(
                  color: Theme.of(context).accentColor,
                  minWidth: 100,
                  height: 50,
                  onPressed: () {
                    attraction.getCoordinate() != null
                        ? _mapView(attraction)
                        : displayMsg(
                            'Location unknown for this attraction', context);
                  },
                  child: const Text(
                    'Location',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                ),
                MaterialButton(
                  color: Theme.of(context).accentColor,
                  minWidth: 100,
                  height: 50,
                  onPressed: () {
                    attraction.getURL() != null
                        ? launchWebsite(attraction.getURL(), context)
                        : displayMsg(
                            'Website for this attraction is unknown', context);
                  },
                  child: const Text(
                    'Website',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                ),
                MaterialButton(
                  color: Theme.of(context).accentColor,
                  minWidth: 100,
                  height: 50,
                  child: const Text(
                    'Give review',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  onPressed: () {
                    var route = MaterialPageRoute(
                        builder: (BuildContext context) => RatingState(
                              attraction: attraction,
                            ));
                    Navigator.of(context).push(route);
                  },
                ),
              ],
            )
          ],
        ),
      );
    }));
  }

  void _mapView(Attraction attraction) {
    Coordinate tempCoordinate =
        findMiddlePoint(attraction.getCoordinate(), userLocation);

    attraction.getCoordinate() == null
        ? displayMsg(
            'The location for this attraction is not available', context)
        : Navigator.of(context)
            .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                title: Text(attraction.getName()),
              ),
              body: Container(
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(
                        tempCoordinate.getLat(), tempCoordinate.getLong()),
                    zoom: zoomLevel(distanceBetweenCoordinates(
                            attraction.getCoordinate(), userLocation))
                        .toDouble(),
                  ),
                  layers: [
                    TileLayerOptions(
                      urlTemplate: "https://api.tiles.mapbox.com/v4/"
                          "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                      additionalOptions: {
                        'accessToken':
                            'pk.eyJ1IjoibTQ5OTEiLCJhIjoiY2p1c2QzNnltMGlqcjQzcDVoa3Z1dWk4cSJ9.OI1Jbas1lQYDVp0-W5Xs7g',
                        'id': 'mapbox.streets',
                      },
                    ),
                    MarkerLayerOptions(
                      markers: [
                        Marker(
                          width: 200.0,
                          height: 200.0,
                          point: LatLng(attraction.getCoordinate().getLat(),
                              attraction.getCoordinate().getLong()),
                          builder: (context) => Container(
                                child: Icon(
                                  attraction.getIsFoodPlace() ? Icons.fastfood : Icons.account_balance,
                                  color: attraction.getIsFoodPlace() ? Colors.red :Colors.green,
                                ),
                              ),
                        ),
                        Marker(
                          width: 200.0,
                          height: 200.0,
                          point: LatLng(
                              userLocation.getLat(), userLocation.getLong()),
                          builder: (context) => Container(
                                child: Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }));
  }

  MapController mapController = MapController();

  void _fullMapView(List<Attraction> allAttractions) {
    DataContainerState data = DataContainer.of(context);
    allAttractions.length == 0 || allAttractions == null
        ? displayMsg('No attractions nearby', context)
        : Navigator.of(context)
            .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Nearby attractions'),
              ),
              body: Stack(
                children: <Widget>[
                  Container(
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        center: LatLng(
                            userLocation.getLat(), userLocation.getLong()),
                        zoom: 15.0,
                      ),
                      layers: [
                        TileLayerOptions(
                          urlTemplate: "https://api.tiles.mapbox.com/v4/"
                              "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                          additionalOptions: {
                            'accessToken':
                                'pk.eyJ1IjoibTQ5OTEiLCJhIjoiY2p1c2QzNnltMGlqcjQzcDVoa3Z1dWk4cSJ9.OI1Jbas1lQYDVp0-W5Xs7g',
                            'id': 'mapbox.streets',
                          },
                        ),
                        MarkerLayerOptions(
                          markers: createMarkers(data.getcreateRecAttOnly()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }));
  }

  List<Marker> createMarkers(bool recOnly /*List<Attraction> allAttractions*/) {
    DataContainerState data = DataContainer.of(context);
    List<Attraction> allAttractions = recOnly
        ? data.getAttractions() ?? List<Attraction>()
        : data.getAllNearbyAttractions() ?? List<Attraction>();

    List<Marker> returnList = [];
    for (Attraction item in allAttractions) {
      returnList.add(
        Marker(
          width: 200.0,
          height: 200.0,
          point: LatLng(
              item.getCoordinate().getLat(), item.getCoordinate().getLong()),
          builder: (context) => Container(
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: buildRecCardTile(item),
                            contentPadding:
                                const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                          );
                        });
                  },
                  child: Icon(
                    item.getIsFoodPlace()
                        ? Icons.fastfood
                        : Icons.account_balance,
                    color: item.getIsFoodPlace() ? Colors.red : Colors.green,
                  ),
                ),
              ),
        ),
      );
    }
    returnList.add(new Marker(
      width: 200.0,
      height: 200.0,
      point: LatLng(userLocation.getLat(), userLocation.getLong()),
      builder: (context) => Container(
            child: Icon(
              Icons.my_location,
              color: Colors.blue,
            ),
          ),
    ));

    return returnList;
  }

  void setUserloc(Position pos) {
    setState(() {
      userLocation = Coordinate(pos.latitude, pos.longitude);
    });
  }

  void updateUserLocation() async {
    if (await PermissionHandler()
            .checkPermissionStatus(PermissionGroup.location) ==
        PermissionStatus.granted) {
      try {
        await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high).then(setUserloc);
      } catch (exception, stackTrace) {
        print('----------------------------------------------------------------------------');
        print('home_screen/updateUserLocation():');
        print(exception);
        print(stackTrace);
        print('----------------------------------------------------------------------------');
      }
    }
    //To be used, when we fix ERROR_ALREADY_REQUESTING_PERMISSIONS error z.z
    else {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.location]);
      if (permissions[PermissionGroup.location] == PermissionStatus.granted) {
        Position position = await Geolocator()
            .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
        userLocation = Coordinate(position.latitude, position.longitude);
      }
    }
  }

  DateTime lastupdatedRec = DateTime.now();
  DateTime lastupdatedAll = DateTime.now();
  DateTime lastupdatedLoc = DateTime.now();

  @override
  Widget build(BuildContext context) {
    DateTime currentTime = DateTime.now();
    var diffLoc = currentTime.minute - lastupdatedLoc.minute;
    if (diffLoc < 0) {
      diffLoc += 60;
    }

    if (username == null) {
      return LogInState();
    }
    return _homeScreen();
  }

  @override
  void didChangeDependencies() {
    loadInt('dist').then(loadDist);
    loadString('tripType').then(loadTripType);

    DataContainerState data = DataContainer.of(context);
    getRecommendations(userLocation, context).then(loadRecs);
    getAllAttractions(userLocation, context).then(loadAllRecs);
    getLikedAttraction(context).then(loadLikedRecs);
    super.didChangeDependencies();
  }

  void loadUser(String userName) {
    setState(() {
      this.username = userName;
      updateUserLocation();
    });
  }

  void loadDist(int maxDist) {
    DataContainerState data = DataContainer.of(context);
    setState(() {
      this.maxDist = maxDist;
      data.setDist(maxDist);
    });
  }

  void loadDistPenEnabled(bool value) {
    if (value == null) {
      setState(() {
        this.distPenEnabled = true;
      });
    } else {
      setState(() {
        this.distPenEnabled = value;
      });
    }
  }

  void loadRecs(List<Attraction> list) {
    DateTime currentTime = DateTime.now();
    DataContainerState data = DataContainer.of(context);
    //var diffRec = currentTime.minute - lastupdatedRec.minute;
    var diff = currentTime.second - lastupdatedRec.second;
    if (diff < 0) {
      diff += 60;
    }

    if (data.getAttractions() != null &&
        (data.getAttractions().length == 0 || diff > 5)) {
      setState(() {
        data.setAttractions(list);
      });
      lastupdatedRec = DateTime.now();
    }
    refreshDistancePenalty();
  }

  void loadAllRecs(List<Attraction> list) {
    DateTime currentTime = DateTime.now();
    DataContainerState data = DataContainer.of(context);
    //var diffRec = currentTime.minute - lastupdatedRec.minute;
    var diff = currentTime.second - lastupdatedAll.second;
    if (diff < 0) {
      diff += 60;
    }

    if ((data.getAllNearbyAttractions() ?? List<Attraction>()).length == 0 ||
        diff > 5) {
      setState(() {
        data.setAllNearbyAttractions(list);
      });
      lastupdatedAll = DateTime.now();
      setState(() {});
    }
  }

  void loadLikedRecs(List<Attraction> list) {
    DataContainerState data = DataContainer.of(context);
    setState(() {
      data.setFavourites(list);
    });
  }

  void loadTripType(String tt) {
    DataContainerState data = DataContainer.of(context);
    setState(() {
      data.setTripType(tt);
    });
  }

  @override
  void initState() {
    super.initState();
    loadString('currentUser').then(loadUser);
    loadBool('distPenEnabled').then(loadDistPenEnabled);
  }
}

class HomeScreenState extends StatefulWidget {
  @override
  HomeScreen createState() => HomeScreen();
}
