import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'utility.dart';
import 'sign_in.dart';
import 'package:flutter_map/flutter_map.dart';

class homeScreenState extends State<Recommender> {
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
        4.2,
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer mi dolor, sodales vitae tortor in, malesuada vehicula arcu. Ut vitae risus nec sapien aliquet venenatis. Curabitur rutrum augue tincidunt risus elementum, nec dictum nisi malesuada. Aenean tristique ut ante ac consequat. Aliquam fermentum eget nulla id venenatis. Praesent consectetur urna erat, eget posuere sapien auctor ut. Vivamus vestibulum augue quis porta bibendum. Vestibulum diam metus, hendrerit non lobortis vitae, commodo id leo. Maecenas fermentum faucibus pellentesque. Fusce vel sodales neque. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus rutrum odio sed erat tristique, nec mollis leo egestas. Nam varius pellentesque turpis, non dignissim urna sodales sit amet. Suspendisse nec mauris ex. Phasellus blandit odio eget justo aliquet aliquet. Suspendisse non scelerisque neque. Nulla facilisi. Suspendisse interdum sollicitudin felis. Ut non finibus augue. Donec dictum mollis orci. Aliquam laoreet sapien eu laoreet tincidunt. Nunc blandit feugiat elit, ac rhoncus nisl egestas et. Maecenas sit amet euismod ex. Nunc ut dictum diam. Cras posuere purus vitae lectus sagittis porttitor. Aliquam erat volutpat. Aliquam pharetra lectus ut felis tincidunt finibus. Donec ac molestie felis. Aliquam diam mi, luctus at nisl id, mattis sodales tellus. Phasellus sed mauris non arcu finibus dignissim. Donec eget velit tellus. Etiam egestas nunc egestas porta tristique. Donec vulputate ut metus eu vehicula. Cras ut massa nec massa maximus rhoncus non sed nisl. Mauris posuere aliquet pellentesque. Quisque id arcu ut odio fringilla lobortis. Suspendisse condimentum, velit et rutrum aliquam, turpis lectus rhoncus lorem, quis venenatis ex felis sit amet mi. Donec pretium sed diam a viverra. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aliquam fringilla suscipit lorem vel pretium. Donec pretium eros vitae est finibus, feugiat vulputate nulla aliquet. Etiam vitae leo nec ligula condimentum tincidunt. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Quisque tincidunt scelerisque bibendum. Phasellus risus enim, eleifend sit amet tortor ac, lobortis pulvinar eros. Fusce hendrerit posuere nisl ac tincidunt. Maecenas imperdiet gravida metus et auctor. Fusce tempor consequat massa ut vehicula. Integer mollis velit nec lacus commodo, eu cursus leo pulvinar. Integer nec placerat sem. Duis et blandit ligula, sit amet tempor ex. Fusce fringilla vel tortor ut molestie. Fusce at nisl ipsum. Quisque interdum id sapien a faucibus. Nunc ut lectus non lectus maximus mattis. Vestibulum cursus leo sapien, quis imperdiet ex facilisis imperdiet. Nam faucibus euismod ultricies. Nullam id urna maximus diam pretium sodales. Nunc tristique, ex sollicitudin malesuada porttitor, nulla eros dapibus dui, ac ultrices sapien quam at purus. Pellentesque augue nisl, interdum eu est vitae, dictum congue risus. Donec mollis rutrum purus, sit amet euismod ligula luctus ac. Nam id molestie nisi. Nullam sagittis odio nec orci semper, ut ullamcorper massa condimentum. Mauris dignissim enim id imperdiet lacinia.'),
    new Attraction(
        'Tower of London 3', 'Open from 8:00 to 17:30', 'ToL.png', false, 3.8),
    new Attraction(
        'Tower of London 4', 'Open from 8:00 to 17:30', 'ToL.png', false, 5.0),
    new Attraction(
        'Tower of London 5', 'Open from 8:00 to 17:30', 'ToL.png', false, 4.7),
  ];

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

  Widget _homeScreen() {
    return MaterialApp(
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Home'),
            actions: <Widget>[
              new IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    displayMsg('Todo: call correct function', context);
                  }),
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
                    attraction.GetCoordinate() != null ? _mapView(attraction) : displayMsg('Location unknown for this attraction', context);
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
                    attraction.GetURL() != null ? launchWebsite(attraction.GetURL(), context) : displayMsg('Website for this attraction is unknown', context);
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
    Coordinate tempUserCoordinate = new Coordinate(attraction.GetCoordinate().GetLat()+0.01, attraction.GetCoordinate().GetLong()+0.01);
    Coordinate tempCoordinate = findMiddlePoint(attraction.GetCoordinate(), tempUserCoordinate);
    
    attraction.GetCoordinate() == null ? displayMsg('Location for attraction is unknown', context) :
    Navigator.of(context)
        .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
      return new Scaffold(
        appBar: AppBar(
          title: Text(attraction.GetName()),
        ),
        body: Container(
          child: FlutterMap(
            options: new MapOptions(
              center: new LatLng(tempCoordinate.GetLat(), tempCoordinate.GetLong()), // Ændre det her til at være midten mellem attraction og user
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
                    point:
                        new LatLng(attraction.GetCoordinate().GetLat(), attraction.GetCoordinate().GetLong()),
                    builder: (context) => new Container(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                        ),
                  ),
                  new Marker(   //Her skal det være userens placering
                    width: 200.0,
                    height: 200.0,
                    point:
                        new LatLng(tempUserCoordinate.GetLat(), tempUserCoordinate.GetLong()),
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

  @override
  Widget build(BuildContext context) {
    return _homeScreen();
  }



}
