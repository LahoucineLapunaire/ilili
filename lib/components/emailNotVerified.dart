import 'package:flutter/material.dart';
import 'package:ilili/components/login.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class EmailNotVerified extends StatelessWidget {
  const EmailNotVerified({super.key});

  goToLogin() {
    auth.signOut();
  }

  sendEmailVerification() {
    auth.currentUser!.sendEmailVerification();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Color(0xFF6A1B9A), // Change this to your desired color
        ),
        title: 'ilili',
        home: Scaffold(
          body: Scaffold(
              backgroundColor: Color(0xFFECEFF1),
              body: Center(
                  child: Container(
                width: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "An email has been sent to your email address, please verify it",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6A1B9A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          sendEmailVerification();
                        },
                        child: Text("Resend email verification")),
                    SizedBox(height: 20),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6A1B9A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          goToLogin();
                        },
                        child: Text("Go to login page")),
                  ],
                ),
              ))),
        ));
  }
}
