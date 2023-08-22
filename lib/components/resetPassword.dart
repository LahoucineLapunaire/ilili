import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ilili/components/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ilili/components/widget.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextTop(),
            SizedBox(height: 50),
            EmailSection(),
            SizedBox(height: 50),
          ],
        ),
      ),
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
          padding: EdgeInsets.only(left: 20),
          width: double.maxFinite,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "Reset Password",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Enter your email to reset your password",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            )
          ]),
        )
      ],
    );
  }
}

class EmailSection extends StatefulWidget {
  const EmailSection({super.key});

  @override
  State<EmailSection> createState() => _EmailSectionState();
}

class _EmailSectionState extends State<EmailSection> {
  TextEditingController emailController = TextEditingController();
  bool confirmation = false;

  Future<void> sendPasswordResetEmail() async {
    showErrorMessage("All fields must be filled", context);
    if (emailController.text == '') {
      return;
    }
    try {
      await auth
          .sendPasswordResetEmail(email: emailController.text)
          .then((value) {
        setState(() {
          confirmation = true;
        });
      });
      showInfoMessage('Password reset email sent successfully', context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
      print('Password reset email sent successfully');
    } catch (e) {
      showErrorMessage(e.toString().split('] ')[1], context);
      print('Error sending password reset email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 300,
        child: Column(
          children: [
            if (confirmation)
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 5),
                    Container(
                      width: 250,
                      child: Text(
                        "Password reset email sent successfully, please check your email",
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.email),
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                sendPasswordResetEmail();
              },
              child: Text(
                "Reset Password",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A1B9A),
                minimumSize: Size(250, 50),
              ),
            )
          ],
        ));
  }
}
