import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ilili/components/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ilili/components/widget.dart';
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
            SizedBox(height: 20),
            EmailSection(),
            SizedBox(height: 20),
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
    return const Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        "To change your email, plus fill the field with your new email.",
        style: TextStyle(),
      ),
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
    showErrorMessage("All fields must be filled", context);
    if (emailController.text == '') {
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
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                sendEmailResetEmail();
              },
              child: Text('Reset Email'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fixedSize:
                    Size(150, 25), // Set the width and height of the button
                backgroundColor:
                    Color(0xFF6A1B9A), // Set the background color of the button
              ),
            ),
          ],
        ));
  }
}
