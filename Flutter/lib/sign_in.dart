import 'package:flutter/material.dart';
import 'utility.dart';
import 'home_screen.dart';

class LogIn extends State<LogInState> {
  final signUpUserNameController = TextEditingController();
  final signUpEmailController = TextEditingController();
  final signUpPasswordController = TextEditingController();
  final signUpPasswordControllerRepeat = TextEditingController();
  final logInUsernamecontroller = TextEditingController();
  final logInPasswordcontroller = TextEditingController();

  HomeScreen home = new HomeScreen();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    signUpEmailController.dispose();
    signUpUserNameController.dispose();
    signUpPasswordController.dispose();
    signUpPasswordControllerRepeat.dispose();
    logInPasswordcontroller.dispose();
    logInUsernamecontroller.dispose();
    super.dispose();
  }

  Widget _logInScreen() {
    return Scaffold(
      backgroundColor: Color(0xFFCAF8F3),
      body: Center(
        child: Container(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(children: <Widget>[
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
              ]),
              Column(
                children: <Widget>[
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                  ),
                  MaterialButton(
                    minWidth: 300,
                    height: 70,
                    onPressed: () {
                      _pushLoginScreen();
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 24.0,
                      ),
                    ),
                    color: Color(0xFFFFFDD0),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pushLoginScreen() {
    Navigator.of(context)
        .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
      return new Scaffold(
        appBar: new AppBar(
          title: const Text('Log in'),
          backgroundColor: Colors.lightBlue,
        ),
        body: Form(
          key: _formKey,
          child: Center(
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new Container(
                    width: 375,
                    child: new TextFormField(
                      controller: logInUsernamecontroller,
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
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new Container(
                    width: 375,
                    child: new TextFormField(
                      controller: logInPasswordcontroller,
                      decoration: new InputDecoration(
                        labelText: "Password",
                        fillColor: Colors.white,
                        filled: true,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(25.0),
                          borderSide: new BorderSide(),
                        ),
                      ),
                      validator: (val) {
                        if (val.length == 0) {
                          return "Password cannot be empty";
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    minWidth: 300,
                    height: 70,
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        //TODO login stuff api makker
                        // det herunder skal fjernes
                        logInPasswordcontroller.text = 'det virker';
                      }
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(fontSize: 24.0),
                    ),
                    color: Color(0xFFFFFDD0),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Color(0xFFCAF8F3),
      );
    }));
  }

  void _pushNewUser() {
    Navigator.of(context)
        .push(new MaterialPageRoute<void>(builder: (BuildContext context) {
      return new Scaffold(
        appBar: new AppBar(
          title: const Text('New user'),
          backgroundColor: Colors.lightBlue,
        ),
        body: Form(
          key: _formKey,
          child: Center(
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new Container(
                    width: 375,
                    child: new TextFormField(
                      controller: signUpUserNameController,
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
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new Container(
                    width: 375,
                    child: new TextFormField(
                      controller: signUpEmailController,
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
                        } else if (!val.contains('@')) {
                          return 'Invalid email';
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new Container(
                    width: 375,
                    child: new TextFormField(
                      controller: signUpPasswordController,
                      decoration: new InputDecoration(
                        labelText: "Password",
                        fillColor: Colors.white,
                        filled: true,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(25.0),
                          borderSide: new BorderSide(),
                        ),
                      ),
                      validator: (val) {
                        if (val.length == 0) {
                          return "Password cannot be empty";
                        } else {
                          return null;
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new Container(
                    width: 375,
                    child: new TextFormField(
                      controller: signUpPasswordControllerRepeat,
                      decoration: new InputDecoration(
                        labelText: "Repeat password",
                        fillColor: Colors.white,
                        filled: true,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(25.0),
                          borderSide: new BorderSide(),
                        ),
                      ),
                      validator: (val) {
                        if (val != signUpPasswordController.text) {
                          return 'Passwords do not match';
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    minWidth: 300,
                    height: 70,
                    onPressed: () {
                      //TODO vi mangler password felt og ændre streng herunder
                      //checkSignUp(signUpUserNameController.text, 'tbd', context);
                      if (_formKey.currentState.validate()) {
                        saveString(
                            'currentUser', signUpPasswordController.text);
                        Navigator.pushNamed(context, '/');
                      }
                    },
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 24.0),
                    ),
                    color: Color(0xFFFFFDD0),
                  ),
                ),
              ],
            ),
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
