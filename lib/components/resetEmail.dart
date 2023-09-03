import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/widget.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class ResetEmail extends StatefulWidget {
  const ResetEmail({Key? key}) : super(key: key);

  @override
  _ResetEmailState createState() => _ResetEmailState();
}

class _ResetEmailState extends State<ResetEmail> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
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
          padding: const EdgeInsets.only(left: 20),
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

  // This function is used to send a password reset email to the current user.
  Future<void> sendEmailResetEmail() async {
    // Check if the email field is empty.
    if (emailController.text == '') {
      showErrorMessage("All fields must be filled", context);
      return;
    }

    try {
      // Attempt to update the current user's email with the new email provided.
      await auth.currentUser?.updateEmail(emailController.text);

      // If the email update is successful, show a success message.
      showInfoMessage('Email changed successfully', context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
    } catch (e) {
      // If there's an error during the email update, show an error message.
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
                prefixIcon: const Icon(Icons.email),
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                sendEmailResetEmail();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                minimumSize: const Size(250, 50),
              ),
              child: const Text(
                "Change Email",
              ),
            )
          ],
        ));
  }
}
