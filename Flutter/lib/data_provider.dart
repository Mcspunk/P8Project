import 'package:flutter/material.dart';
import 'data_container.dart';

 class DataProvider extends InheritedWidget {
  DataProvider({Key key, this.child, this.dataContainer}) : super(key: key, child: child);

  //DataCOntainer holds all the relevant data, pulled from DB on app startup
  final DataContainer dataContainer;
  final Widget child;

  static DataProvider of(BuildContext context) {
    //Tries to find widget in the context that matches the type DataProvider
    //The cast is made as inheritFromWidgetOfExactType returns widget. which is also a DataProvider.
    return (context.inheritFromWidgetOfExactType(DataProvider)as DataProvider);
  }

  @override
  bool updateShouldNotify( DataProvider oldWidget) {
    return true;
  }
}