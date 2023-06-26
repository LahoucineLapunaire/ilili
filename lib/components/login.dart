import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/signup.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void login() {
    auth
        .signInWithEmailAndPassword(email: "test@test.com", password: "testest")
        .then((value) => print("User ${value.user?.email} logged in"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
          ),
          ElevatedButton(
              onPressed: () {
                login();
              },
              child: Text('Login')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignupPage(), // Destination screen
                  ),
                );
              },
              child: Text('To Signup')),
        ],
      )),
    );
  }
}
