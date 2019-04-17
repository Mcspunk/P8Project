import 'package:flutter/material.dart';
import 'utility.dart';
import 'sign_in.dart';

class homeScreenState extends State<Recommender> {
  Widget _homeScreen() {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            
            bottom: TabBar(tabs: [
              Tab(
                icon: Icon(Icons.flag),
              ),
              Tab(
                icon: Icon(Icons.fastfood),
              ),
              Tab(
                icon: Icon(Icons.map),
              ),
            ]),
          ),
          body: TabBarView(
            children: [
              _attractionView(),
              _attractionView(),
              _attractionView(),
              //_restaurantView(),
              //_mapView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attractionView(){
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
          ),
          RaisedButton(onPressed: () {displayMsg('Test', context);},)         
        ],
      ),
    );
  }

  Widget _restaurantView() {

  }

Widget _mapView() {

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HyReSy'),
      ),
      body: _homeScreen(),
    );
  }
}
