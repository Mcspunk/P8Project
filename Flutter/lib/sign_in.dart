import 'package:flutter/material.dart';
import 'utility.dart';
import 'home_screen.dart';


class LogIn extends State<LogInState> {
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  HomeScreen home = new HomeScreen();

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Widget _logInScreen() {
    return Scaffold(
      backgroundColor: Color(0xFFCAF8F3),
      body: Center(
        child: Column(children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
          ),
          MaterialButton(
            minWidth: 300,
            height: 70,
            onPressed: () {
              displayMsg('Facebook not implemented yet', context);
            },
            child: const Text('Facebook',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                )),
            color: Color(0xFF3C5A99),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
          ),
          MaterialButton(
            minWidth: 300,
            height: 70,
            onPressed: () {
              displayMsg('Twitter not implemented yet', context);
            },
            child: const Text('Twitter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                )),
            color: Color(0xFF1DA1F2),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
          ),
          MaterialButton(
            minWidth: 300,
            height: 70,
            onPressed: () {
              displayMsg('Google not implemented yet', context);
            },
            child: const Text('Google',
                style: TextStyle(color: Colors.white, fontSize: 24.0)),
            color: Color(0xFFD44638),
          ),
          Padding(
            padding: const EdgeInsets.all(112.0),
          ),
          MaterialButton(
            minWidth: 300,
            height: 70,
            onPressed: () {
              _pushNewUser();
            },
            child: const Text(
              'New User',
              style: TextStyle(
                fontSize: 24.0,
              ),
            ),
            color: Color(0xFFFFFDD0),
          ),
        ]),
      ),
    );
  }

  void _pushNewUser() {
    Navigator.of(context)
        .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
      return new Scaffold(
        appBar: new AppBar(
          title: const Text('New user'),
          backgroundColor: Colors.lightBlue,
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
              ),
              new Container(
                width: 375,
                child: new TextFormField(
                  controller: userNameController,
                  decoration: new InputDecoration(
                    labelText: "Username",
                    fillColor: Colors.white,
                    filled: true,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(25.0),
                      borderSide: new BorderSide(),
                    ),
                  ),
                  validator: (val) {
                    if (val.length == 0) {
                      return "Username cannot be empty";
                    } else {
                      return null;
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
              ),
              new Container(
                width: 375,
                child: new TextFormField(
                  controller: emailController,
                  decoration: new InputDecoration(
                    labelText: "Email",
                    fillColor: Colors.white,
                    filled: true,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(25.0),
                      borderSide: new BorderSide(),
                    ),
                  ),
                  validator: (val) {
                    if (val.length == 0) {
                      return "Email cannot be empty";
                    } else {
                      return null;
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(166.0),
              ),
              MaterialButton(
                minWidth: 300,
                height: 70,
                onPressed: () {       
                  saveString('currentUser', userNameController.text);      
                  Navigator.pushNamed(context, '/');
                },
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 24.0),
                ),
                color: Color(0xFFFFFDD0),
              ),
            ],
          ),
        ),
        backgroundColor: Color(0xFFCAF8F3),
      );
    }));
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

class LogInState extends StatefulWidget {
  @override
  LogIn createState() => LogIn();
}
