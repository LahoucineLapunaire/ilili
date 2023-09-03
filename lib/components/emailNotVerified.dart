import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class EmailNotVerified extends StatelessWidget {
  const EmailNotVerified({super.key});

  // Function to sign out the currently authenticated user.
  void goToLogin() {
    // Using Firebase Authentication, sign out the current user.
    auth.signOut();
  }

// Function to send an email verification link to the current user.
  void sendEmailVerification() {
    // Retrieve the currently authenticated user and send an email verification link.
    // This will allow the user to verify their email address.
    auth.currentUser!.sendEmailVerification();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor:
            const Color(0xFF6A1B9A), // Change this to your desired color
      ),
      title: 'ilili',
      home: Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: Center(
              child: Container(
            width: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TextTop(),
                const SizedBox(height: 50),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    minimumSize: const Size(250, 50),
                  ),
                  onPressed: () => sendEmailVerification(),
                  child: const Text("Resend Email"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    minimumSize: const Size(250, 50),
                  ),
                  onPressed: () => goToLogin(),
                  child: const Text("Login"),
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
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          width: double.maxFinite,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                const Icon(
                  Icons.email,
                  size: 40,
                ),
                const SizedBox(width: 10),
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
            const SizedBox(height: 20),
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
