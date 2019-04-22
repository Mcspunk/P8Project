import 'package:flutter/material.dart';
import 'utility.dart';
import 'sign_in.dart';

class homeScreenState extends State<Recommender> {
  final attractions = [
    new Attraction(
        'Tower of London', 'Open from 8:00 to 17:30', 'ToL.png', false, 4.8),
    new Attraction(
        'Tower of London 2', 'Open from 8:00 to 17:30', 'ToL.png', false, 4.2),
    new Attraction(
        'Tower of London 3', 'Open from 8:00 to 17:30', 'ToL.png', false, 3.8),
    new Attraction(
        'Tower of London 4', 'Open from 8:00 to 17:30', 'ToL.png', false, 5.0),
    new Attraction(
        'Tower of London 5', 'Open from 8:00 to 17:30', 'ToL.png', false, 4.7),
  ];

  final foodPlaces = [
    new Attraction(
        'Mc Donald\'s', 'Open from 0:00 to 24:00', 'mcd.png', true, 3.8),
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
          return buildRecTile(items[index], items[index].GetIsFoodPlace());
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
    return _buildRecList(likedAttractions);
  }

  Widget buildRecTile(Attraction attraction, bool isFoodPlace) {
    return new Column(
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
                            // bottomLeft
                            offset: Offset(-1.5, -1.5),
                            color: Colors.black),
                        Shadow(
                            // bottomRight
                            offset: Offset(1.5, -1.5),
                            color: Colors.black),
                        Shadow(
                            // topRight
                            offset: Offset(1.5, 1.5),
                            color: Colors.black),
                        Shadow(
                            // topLeft
                            offset: Offset(-1.5, 1.5),
                            color: Colors.black),
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
    );
  }

  


  @override
  Widget build(BuildContext context) {
    return _homeScreen();
  }
}
