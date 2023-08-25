import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Ilili/components/widget.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class ResetEmail extends StatefulWidget {
  const ResetEmail({Key? key}) : super(key: key);

  @override
  _ResetEmailState createState() => _ResetEmailState();
}

class _ResetEmailState extends State<ResetEmail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
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
              "Change Email",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Enter your new email",
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

  Future<void> sendEmailResetEmail() async {
    if (emailController.text == '') {
      showErrorMessage("All fields must be filled", context);
      return;
    }
    try {
      await auth.currentUser?.updateEmail(emailController.text);
      showInfoMessage('Email changed successfully', context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
    } catch (e) {
      showErrorMessage(e.toString().split('] ')[1], context);
      print('Error sending Email reset email : \n $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 300,
        child: Column(
          children: [
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
                sendEmailResetEmail();
              },
              child: Text(
                "Change Email",
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
