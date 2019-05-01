import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'utility.dart';
import 'package:flutter_map/flutter_map.dart';
import 'sign_in.dart';
import 'dart:async';
import 'notification_helper.dart';
import 'package:flutter/material.dart';
import 'dart:isolate';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends State<HomeScreenState> {
  final attractions = [
    new Attraction(
        'Tower of London',
        'Open from 8:00 to 17:30',
        'ToL.png',
        false,
        4.8,
        'A tower in London',
        'https://www.hrp.org.uk/tower-of-london/',
        51.508144,
        -0.07626),
    new Attraction(
        'Tower of London 2',
        'Open from 8:00 to 17:30',
        'ToL.png',
        false,
        4.8,
        'A tower in London 3',
        'https://www.hrp.org.uk/tower-of-london/',
        51.528144,
        -0.04626),
    new Attraction(
        'Tower of London 4',
        'Open from 8:00 to 17:30',
        'ToL.png',
        false,
        4.8,
        'A tower in London',
        'https://www.hrp.org.uk/tower-of-london/',
        51.538144,
        -0.05626),
    new Attraction(
        'Tower of London 5',
        'Open from 8:00 to 17:30',
        'ToL.png',
        false,
        4.8,
        'A tower in London',
        'https://www.hrp.org.uk/tower-of-london/',
        51.548144,
        -0.06626),
  ];

  
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();


  Isolate _isolate;
  bool _running = false;
  static int _counter = 0;
  String notification = "";
  ReceivePort _receivePort;

  void _start() async {
    _running = true;
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_checkTimer, _receivePort.sendPort);
    _receivePort.listen(_handleMessage, onDone:() {
        print("done!");
    });
  }

  static void _checkTimer(SendPort sendPort) {
    Timer.periodic(new Duration(seconds: 1), (Timer t) {
      _counter++;
      String msg = _counter.toString();      
      print('SEND: ' + msg);      
      sendPort.send(msg);
    });
  }

  void _handleMessage(dynamic data) {
    print('RECEIVED: ' + data);
    /*if (int.parse(data) == 5) {
      singlePOINotif(flutterLocalNotificationsPlugin, title: 'Counter notification', body: 'Counter is now ' + data.toString());
    }*/
    setState(() {      
      notification = data;
    });
  }

  void _stop() {
    if (_isolate != null) {
      setState(() {
          _running = false; 
          notification = '';   
      });
      _receivePort.close();
      _isolate.kill(priority: Isolate.immediate);
      _isolate = null;        
      }
  }

  final foodPlaces = [
    new Attraction('Mc Donald\'s', 'Open from 0:00 to 24:00', 'mcd.png', true,
        3.8, 'Family restaurant', 'https://www.mcdonalds.com/'),
    new Attraction(
        'Mc Donald\'s 2', 'Open from 0:00 to 24:00', 'mcd.png', true, 3.9),
    new Attraction(
        'Mc Donald\'s 3', 'Open from 0:00 to 24:00', 'mcd.png', true, 3.2),
    new Attraction(
        'Mc Donald\'s 4', 'Open from 0:00 to 24:00', 'mcd.png', true, 3.3),
    new Attraction(
        'Mc Donald\'s 5', 'Open from 0:00 to 24:00', 'mcd.png', true, 4.2),
  ];

  final likedAttractions = [];
  String username = null;
  Widget _homeScreen() {
    return MaterialApp(
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Home'),
            actions: <Widget>[
              new IconButton( //Tror ikke det er her den her funktionalitet skal være, men kunne ikke få lov til at lave en tab mere
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    _fullMapView(attractions); // Det her skal være en liste af alle attractions inden for en radius
                  }),
              new IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  }),
              new RaisedButton(
                  child: Text('Show notif'), 
                  onPressed: () => singlePOINotif(flutterLocalNotificationsPlugin,
                  title: 'Counter title', body: 'NU 5 brah'),
              )
              
            ],
            bottom: TabBar(tabs: [
              Tab(
                icon: Icon(Icons.home),
              ),
              Tab(
                icon: Icon(Icons.landscape),
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
        
        /*  floatingActionButton: new FloatingActionButton(
            onPressed: () => _running ? _stop : _start,
            tooltip: _running ? 'Timer stop' : 'Timer start',
            child: _running ? new Icon(Icons.stop) : new Icon(Icons.play_arrow),
          ),    */ 
             
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
          return buildRecTile(items[index]);
        }
      },
    );
  }

  Widget _attractionView() {
    return _buildRecList(attractions);
  }

  Widget _allView() {
    List<Attraction> allList = [];
    int x = 0;

    if (attractions.length < foodPlaces.length) {
      x = foodPlaces.length;
    } else {
      x = attractions.length;
    }

    for (var i = 0; i < x; i++) {
      Attraction f = foodPlaces[i];

      allList.add(f);
      if (i < attractions.length) {
        Attraction a = attractions[i];
        allList.add(a);
      }
    }

    return _buildRecList(allList);
  }

  Widget _restaurantView() {
    return _buildRecList(foodPlaces);
  }

  Widget _likeView() {
    return likedAttractions.length != 0
        ? _buildRecList(likedAttractions)
        : new ListTile(
            title: Text('No liked attractions'),
            subtitle: Text(
                'Tap the heart icon on the attractions to save them to your list of liked attractions'),
            trailing: Icon(Icons.info_outline),
          );
  }

  Widget buildRecTile(Attraction attraction) {
    return new GestureDetector(
        onTap: () {
          _detailedAttractionView(attraction);
        },
        child: Column(
          children: <Widget>[
            Container(
                constraints: new BoxConstraints.expand(
                  height: 200.0,
                ),
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
                            Shadow(
                                offset: Offset(-1.5, -1.5),
                                color: Colors.black),
                            Shadow(
                                offset: Offset(1.5, -1.5), color: Colors.black),
                            Shadow(
                                offset: Offset(1.5, 1.5), color: Colors.black),
                            Shadow(
                                offset: Offset(-1.5, 1.5), color: Colors.black),
                          ],
                        )),
                    trailing: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (likedAttractions.contains(attraction)) {
                              likedAttractions.remove(attraction);
                            } else {
                              likedAttractions.add(attraction);
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
                              color: likedAttractions.contains(attraction)
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
        ));
  }

  void _detailedAttractionView(Attraction attraction) {
    Navigator.of(context)
        .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text(attraction.GetName())),
        body: Column(
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
                  onPressed: () {
                    displayMsg('WIP', context);
                  },
                  child: const Text(
                    'Give review',
                    style: TextStyle(fontSize: 18.0),
                  ),
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
                          //Her skal det være userens placering
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
                        allAttractions[0].GetCoordinate().GetLat(),
                        allAttractions[0]
                            .GetCoordinate()
                            .GetLong()), //Det her skal være userens placering
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
                      markers: createMarkers(allAttractions),
                    ),
                  ],
                ),
              ),
            );
          }));
  }

  List<Marker> createMarkers(List<Attraction> allAttractions) {
    List<Marker> returnList = [];
    for (Attraction item in allAttractions) {
      returnList.add(
        new Marker(
          width: 200.0,
          height: 200.0,
          point: new LatLng(
              item.GetCoordinate().GetLat(), item.GetCoordinate().GetLong()),
          builder: (context) => new Container(
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),
              ),
        ),
      );
    }
    return returnList;
  }

  @override
  Widget build(BuildContext context) {
    if (username == null) {
      return LogInState();
    }

    return _homeScreen();
  }

  @override
  void initState() {
    loadString('currentUser').then(loadUser);
    super.initState();  

    /*
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('app_icon');

    var initializationSettingsIOS = new IOSInitializationSettings(
    onDidReceiveLocalNotification: onDidRecieveLocationLocation);

    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
        flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
   */
            
  }

/*
  //TODO IOS specific navigation
  Future onDidRecieveLocationLocation(int id, String title, String body, String payload) {
     
  }
        
  //Ikke sikker på at denne navigation er korrekt
  Future onSelectNotification(String payload) {
    MaterialPageRoute(builder: (context) => HomeScreenState());
  }*/

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
