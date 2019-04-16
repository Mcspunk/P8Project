import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
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