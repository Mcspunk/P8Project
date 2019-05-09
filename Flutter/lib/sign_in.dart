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

  HomeScreen home = HomeScreen();

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
                    color: Theme.of(context).accentColor,
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
                    color: Theme.of(context).accentColor,
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
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Log in'),
        ),
        body: Form(
          key: _formKey,
          child: Center(
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 375,
                    child: TextFormField(
                      controller: logInUsernamecontroller,
                      style: Theme.of(context).textTheme.body2,
                      decoration: InputDecoration(
                        labelStyle: Theme.of(context).textTheme.body2,
                        labelText: "Username",
                        filled: true,
                        border: OutlineInputBorder(
                          //borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(),
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
                  child: Container(
                    width: 375,
                    child: TextFormField(
                      controller: logInPasswordcontroller,
                       style: Theme.of(context).textTheme.body2,
                      decoration: InputDecoration(
                        labelStyle: Theme.of(context).textTheme.body2,
                        labelText: "Password",
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide:BorderSide(),
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
                        checkLogIn(logInUsernamecontroller.text.toString(), logInPasswordcontroller.text, context);
                      }
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(fontSize: 24.0),
                    ),
                    color: Theme.of(context).accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }));
  }

  void _pushNewUser() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('New user'),
        ),
        body: Form(
          key: _formKey,
          child: Center(
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 375,
                    child: TextFormField(
                      controller: signUpUserNameController,
                      style: Theme.of(context).textTheme.body2,
                      decoration: InputDecoration(
                        labelStyle: Theme.of(context).textTheme.body2,
                        labelText: "Username",
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(),
                          
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
                  child: Container(
                    width: 375,
                    child: TextFormField(
                      controller: signUpEmailController,
                     style: Theme.of(context).textTheme.body2,
                      decoration: InputDecoration(
                        labelStyle: Theme.of(context).textTheme.body2,
                        labelText: "Email",
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(),
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
                  child: Container(
                    width: 375,
                    child: TextFormField(
                      controller: signUpPasswordController,
                      style: Theme.of(context).textTheme.body2,
                      decoration: InputDecoration(
                        labelStyle: Theme.of(context).textTheme.body2,
                        labelText: "Password",
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(),
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
                  child: Container(
                    width: 375,
                    child: TextFormField(
                      controller: signUpPasswordControllerRepeat,
                      style: Theme.of(context).textTheme.body2,
                      decoration: InputDecoration(
                        labelStyle: Theme.of(context).textTheme.body2,
                        labelText: "Repeat Password",
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(),
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
                        saveString('currentUser', signUpUserNameController.text.toString());
                        Navigator.pushNamedAndRemoveUntil(context, '/context_prompt', (Route<dynamic> route) => false);
                      }
                    },
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 24.0),
                    ),
                    color: Theme.of(context).accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
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
