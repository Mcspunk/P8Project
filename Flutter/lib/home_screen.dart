import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'package:test2/data_container.dart';
import 'utility.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'sign_in.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'data_provider.dart';
import 'dart:io';

class RatingDialog extends State<RatingState> {
  //https://www.youtube.com/watch?v=MsycCv5r2Wo
  double attractionRating = 0;
  String tripType = 'Solo';
  DateTime selectedTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate ' + widget.attraction.GetName()),
      ),
      body: ListView(
        children: <Widget>[
          Container(
              constraints: new BoxConstraints.expand(
                height: 200.0,
              ),
              alignment: Alignment.bottomLeft,
              padding: new EdgeInsets.only(left: 4.0, bottom: 2.0),
              decoration: new BoxDecoration(
                image: new DecorationImage(
                  image: new AssetImage(widget.attraction.GetImgPath()),
                  fit: BoxFit.cover,
                ),
              ),
              child: ListTile(
                title: new Text(widget.attraction.GetName(),
                    style: new TextStyle(
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
                child: Text('Select date'),
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
                  });
                },
              )),
          Divider(),
          ListTile(
            title: RaisedButton(
              child: Text('Submit review'),
              onPressed: () {
                saveString(widget.attraction.GetName() + '%Rating',
                    attractionRating.toString());
                saveString(
                    widget.attraction.GetName() + '%Date',
                    selectedTime.day.toString() +
                        '/' +
                        selectedTime.month.toString());
                saveString(widget.attraction.GetName() + '%TripType', tripType);
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
  String username = null;
  Widget _homeScreen() {
    DataContainer data = DataProvider.of(context).dataContainer;
    return MaterialApp(
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Home'),
            actions: <Widget>[
              new IconButton(
                  //Tror ikke det er her den her funktionalitet skal være, men kunne ikke få lov til at lave en tab mere
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    updateUserLocation();

                    userLocation == null
                        ? displayMsg(
                            'Your location is not available at the moment, please try again later',
                            context)
                        : _fullMapView(
                            data.getAttractions()); // Det her skal være en liste af alle attractions inden for en radius
                  }),
              new IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  }),
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

  Widget _buildRecList(var items) {
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
    DataContainer data = DataProvider.of(context).dataContainer;
    return _buildRecList(data.getAttractions().where((x) => x.GetIsFoodPlace() == false));
  }

  Widget _allView() {
    DataContainer data = DataProvider.of(context).dataContainer;
    return _buildRecList(data.getAttractions());
  }

  Widget _restaurantView() {
    DataContainer data = DataProvider.of(context).dataContainer;
    return _buildRecList(data.getAttractions().where((x) => x.GetIsFoodPlace() == true));
  }

  Widget _likeView() {
    DataContainer data = DataProvider.of(context).dataContainer;
    return data.getAttractions().length != 0
        ? _buildRecList(data.getAttractions())
        : new ListTile(
            title: Text('No liked attractions'),
            subtitle: Text(
                'Tap the heart icon on the attractions to save them to your list of liked attractions'),
            trailing: Icon(Icons.info_outline),
          );
  }

  Widget buildRecCardTile(Attraction attraction) {
    final deviceSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        _detailedAttractionView(attraction);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              constraints:
                  new BoxConstraints.expand(height: deviceSize.height * 0.3, width: deviceSize.width * 0.85),
              alignment: Alignment.bottomLeft,
              padding: new EdgeInsets.only(left: 4.0, bottom: 2.0),
              decoration: new BoxDecoration(
                image: new DecorationImage(
                  image: new AssetImage(attraction.GetImgPath()),
                  fit: BoxFit.cover,
                ),
              ),
              child: ListTile(
                  title: new Text(attraction.GetName(),
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: Colors.white,
                        shadows: [
                          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                        ],
                      )))),
          ListTile(
              title: Text('Rating: ' + attraction.GetRating().toString()),
              subtitle: Text('Distance 0.8 km'),
              trailing: Text(attraction.GetOpeningHours())),
        ],
      ),
    );
  }

  Widget buildRecTile(Attraction attraction) {
    DataContainer data = DataProvider.of(context).dataContainer;
    final deviceSize = MediaQuery.of(context).size;
    return Column(
      children: <Widget>[
        Container(
            constraints:
                new BoxConstraints.expand(height: deviceSize.height * 0.3),
            alignment: Alignment.bottomLeft,
            padding: new EdgeInsets.only(left: 4.0, bottom: 2.0),
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new AssetImage(attraction.GetImgPath()),
                fit: BoxFit.cover,
              ),
            ),
            child: ListTile(
                title: new Text(attraction.GetName(),
                    style: new TextStyle(
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
                trailing: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (data.getAttractions().contains(attraction)) {
                          data.getAttractions().remove(attraction);
                        } else {
                          data.getAttractions().add(attraction);
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
          title: Text('Rating: ' + attraction.GetRating().toString()),
          subtitle: Text('Distance 0.8 km'),
          trailing: Text(attraction.GetOpeningHours()),
        ),
      ],
    );
  }

  Widget buildInteractiveRecTile(Attraction attraction) {
    return new GestureDetector(
        onTap: () {
          _detailedAttractionView(attraction);
        },
        child: buildRecTile(attraction));
  }

  void _detailedAttractionView(Attraction attraction) {
    Navigator.of(context)
        .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text(attraction.GetName())),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            buildRecTile(attraction),
            Divider(),
            Text(attraction.GetDescription()),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                MaterialButton(
                  minWidth: 100,
                  height: 50,
                  onPressed: () {
                    attraction.GetCoordinate() != null
                        ? _mapView(attraction)
                        : displayMsg(
                            'Location unknown for this attraction', context);
                  },
                  child: const Text(
                    'Location',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  color: Colors.lightBlue,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                ),
                MaterialButton(
                  minWidth: 100,
                  height: 50,
                  onPressed: () {
                    attraction.GetURL() != null
                        ? launchWebsite(attraction.GetURL(), context)
                        : displayMsg(
                            'Website for this attraction is unknown', context);
                  },
                  child: const Text(
                    'Website',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  color: Colors.lightBlue,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                ),
                MaterialButton(
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
                  color: Colors.lightBlue,
                ),
              ],
            )
          ],
        ),
      );
    }));
  }

  Widget _mapView(Attraction attraction) {
    Coordinate tempUserCoordinate = new Coordinate(
        attraction.GetCoordinate().GetLat() + 0.01,
        attraction.GetCoordinate().GetLong() + 0.01);
    Coordinate tempCoordinate =
        findMiddlePoint(attraction.GetCoordinate(), tempUserCoordinate);

    attraction.GetCoordinate() == null
        ? displayMsg('Location for attraction is unknown', context)
        : Navigator.of(context)
            .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
            return new Scaffold(
              appBar: AppBar(
                title: Text(attraction.GetName()),
              ),
              body: Container(
                child: FlutterMap(
                  options: new MapOptions(
                    center: new LatLng(
                        tempCoordinate.GetLat(), tempCoordinate.GetLong()),
                    zoom: 15.0,
                  ),
                  layers: [
                    new TileLayerOptions(
                      urlTemplate: "https://api.tiles.mapbox.com/v4/"
                          "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                      additionalOptions: {
                        'accessToken':
                            'pk.eyJ1IjoibTQ5OTEiLCJhIjoiY2p1c2QzNnltMGlqcjQzcDVoa3Z1dWk4cSJ9.OI1Jbas1lQYDVp0-W5Xs7g',
                        'id': 'mapbox.streets',
                      },
                    ),
                    new MarkerLayerOptions(
                      markers: [
                        new Marker(
                          width: 200.0,
                          height: 200.0,
                          point: new LatLng(attraction.GetCoordinate().GetLat(),
                              attraction.GetCoordinate().GetLong()),
                          builder: (context) => new Container(
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                ),
                              ),
                        ),
                        new Marker(
                          width: 200.0,
                          height: 200.0,
                          point: new LatLng(tempUserCoordinate.GetLat(),
                              tempUserCoordinate.GetLong()),
                          builder: (context) => new Container(
                                child: Icon(
                                  Icons.my_location,
                                  color: Colors.red,
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

  Widget _fullMapView(List<Attraction> allAttractions) {
    allAttractions.length == 0 || allAttractions == null
        ? displayMsg('No attractions nearby', context)
        : Navigator.of(context)
            .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
            return new Scaffold(
              appBar: AppBar(
                title: Text('Nearby attractions'),
              ),
              body: Container(
                child: FlutterMap(
                  options: new MapOptions(
                    center: new LatLng(
                        userLocation.GetLat(), userLocation.GetLong()),
                    /*allAttractions[0].GetCoordinate().GetLat(),
                        allAttractions[0]
                            .GetCoordinate()
                            .GetLong()), */ //Det her skal være userens placering
                    zoom: 15.0,
                  ),
                  layers: [
                    new TileLayerOptions(
                      urlTemplate: "https://api.tiles.mapbox.com/v4/"
                          "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                      additionalOptions: {
                        'accessToken':
                            'pk.eyJ1IjoibTQ5OTEiLCJhIjoiY2p1c2QzNnltMGlqcjQzcDVoa3Z1dWk4cSJ9.OI1Jbas1lQYDVp0-W5Xs7g',
                        'id': 'mapbox.streets',
                      },
                    ),
                    new MarkerLayerOptions(
                      markers: createMarkers(/*allAttractions*/),
                    ),
                  ],
                ),
              ),
            );
          }));
  }

  List<Marker> createMarkers(/*List<Attraction> allAttractions*/) {
    ////////////////////////////////
    DataContainer data = DataProvider.of(context).dataContainer;
    List<Attraction> allAttractions = data.getAttractions();

    ////////////////////////////////

    final deviceSize = MediaQuery.of(context).size;
    final dWidth = deviceSize.width;
    final dWidth10 = dWidth * 0.1;

    final dHeight = deviceSize.height;

    List<Marker> returnList = [];
    for (Attraction item in allAttractions) {
      returnList.add(
        new Marker(
          width: 200.0,
          height: 200.0,
          point: new LatLng(
              item.GetCoordinate().GetLat(), item.GetCoordinate().GetLong()),
          builder: (context) => new Container(
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
                  item.GetIsFoodPlace()
                      ? Icons.fastfood
                      : Icons.account_balance,
                  color: item.GetIsFoodPlace() ? Colors.red : Colors.green,
                ),
              )),
        ),
      );
    }
    returnList.add(new Marker(
      width: 200.0,
      height: 200.0,
      point: new LatLng(userLocation.GetLat(), userLocation.GetLong()),
      builder: (context) => new Container(
            child: Icon(
              Icons.my_location,
              color: Colors.blue,
            ),
          ),
    ));
    
    return returnList;
  }

  void updateUserLocation() async {
    Position position = await Geolocator()
        .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

    position == null
        ? displayMsg('Position not available', context)
        : userLocation = new Coordinate(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    if (username == null) {
      return LogInState();
    }
    
    return _homeScreen();
  }

  @override
  void didChangeDependencoes(){
    super.didChangeDependencies();
    DataContainer data = DataProvider.of(context).dataContainer;
  }

  @override
  void initState() {
    loadString('currentUser').then(loadUser);
    super.initState();
  }

  void loadUser(String userName) {
    setState(() {
      this.username = userName;
    });
  }
}

class HomeScreenState extends StatefulWidget {
  @override
  HomeScreen createState() => HomeScreen();
}

//Lav map over alt der er i nærheden
