import 'package:flutter/material.dart';

class RecommenderState extends State<Recommender> {
  
  Widget _logInScreen(){
    return Scaffold(
      backgroundColor: Color(0xFFCAF8F3),
      body: Center(
        child: Column(
          children: <Widget>[  
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            MaterialButton(
              minWidth: 170,
              height: 50,
              onPressed: () {_logInScreen();},
              child: const Text('Facebook', style: TextStyle(color: Colors.white,)),
              color: Color(0xFF3C5A99),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
            ),
            MaterialButton(
              minWidth: 170,
              height: 50,
              onPressed: () {_logInScreen();},
              child: const Text('Twitter', style: TextStyle(color: Colors.white,)),
              color: Color(0xFF1DA1F2),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
            ),
            MaterialButton(
              minWidth: 170,
              height: 50,
              onPressed: () {_logInScreen();},
              child: const Text('Google'),
              color: Color(0xFFFFFFFF),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
            ),
            MaterialButton(
              minWidth: 170,
              height: 50,
              onPressed: () {_logInScreen();},
              child: const Text('New User'),
              color: Color(0xFFFFFDD0),            
            ),
          ]
        ),
      ),
    );
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign in'),        
      ),
      body: _logInScreen(),
    );
  }
}


class Recommender extends StatefulWidget {
  @override
  RecommenderState createState() => RecommenderState();
}
