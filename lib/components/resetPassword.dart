import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/widget.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
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
          padding: const EdgeInsets.only(left: 20),
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
    // Show an error message if any of the required fields are empty
    showErrorMessage("All fields must be filled", context);

    // Check if the email field is empty and return if it is
    if (emailController.text == '') {
      return;
    }

    try {
      // Attempt to send a password reset email using Firebase Authentication
      await auth
          .sendPasswordResetEmail(email: emailController.text)
          .then((value) {
        // If the password reset email is sent successfully, set 'confirmation' to true
        setState(() {
          confirmation = true;
        });
      });

      // Show a success message if the password reset email is sent successfully
      showInfoMessage('Password reset email sent successfully', context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });

      // Log a success message to the console
      print('Password reset email sent successfully');
    } catch (e) {
      // Show an error message if there's an error and log the error to the console
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
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green),
                    const SizedBox(width: 5),
                    Container(
                      width: 250,
                      child: const Text(
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
                sendPasswordResetEmail();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                minimumSize: const Size(250, 50),
              ),
              child: const Text(
                "Reset Password",
              ),
            )
          ],
        ));
  }
}
