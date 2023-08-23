import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/login.dart';
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
          backgroundColor: Color(0xFFFAFAFA),
          body: Center(
              child: Container(
            width: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextTop(),
                SizedBox(height: 50),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A1B9A),
                    minimumSize: Size(250, 50),
                  ),
                  onPressed: () => sendEmailVerification(),
                  child: Text("Resend Email"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A1B9A),
                    minimumSize: Size(250, 50),
                  ),
                  onPressed: () => goToLogin(),
                  child: Text("Login"),
                ),
              ],
            ),
          ))),
    );
  }
}

class TextTop extends StatelessWidget {
  const TextTop({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
          width: double.maxFinite,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 40,
                ),
                SizedBox(width: 10),
                Text(
                  "An email has been sent !",
                  style: TextStyle(
                    fontFamily: GoogleFonts.poppins().fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Please verify your email address, then login. If you don't receive the email, please check your spam folder or tap on the \"Resend Email\" button.",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 16,
              ),
            )
          ]),
        )
      ],
    );
  }
}
