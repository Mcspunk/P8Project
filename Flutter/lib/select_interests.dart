import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class SelectInterests extends State<Selector> {
  List<String> _categories = ['Park', 'Zoo', 'Museum', 'Casino', 'Indian','1','1','1','1'];
  List<double> _ratings = [0,0,0,0,0,0,0,0,0];
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate recommendation categories'),
      ),
      body: _interestList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.arrow_forward, size: 40,),
        //mangler onPressed
      ),
    );
  }

  
  Widget _interestList() {
    final j = _categories.length;
    List<Widget> widgetList = new List<Widget>();
    widgetList.add(new ListTile(title: Text('Please enter rating for each of the categories. The more you rate the better recommendations you will get. You can click the arrow when you dont want to rate more categories.'),));
    widgetList.add(Divider());
    for (int i = 0; i < j; i++) {
      widgetList.add(new ListTile(
        title: Text(_categories[i]),
        trailing: SmoothStarRating(
            rating: _ratings[i],
            size: 25,
            starCount: 5,
            color: Colors.orange[400],
            borderColor: Colors.grey,
            onRatingChanged: (value) {
              setState(() {
                _ratings[i] = value;
              });
            }),
      ));
      widgetList.add(Divider(height: 20,));
    }
    widgetList.add(new ListTile());
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: widgetList,
    );
  }
}

class Selector extends StatefulWidget {
  @override
  SelectInterests createState() => SelectInterests();
}
