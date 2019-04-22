import 'package:flutter/material.dart';
import 'sign_in.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign in',
      theme: new ThemeData(
        primaryColor: Colors.lightBlue,
      ),
      home: Recommender(),
    );
  }
}