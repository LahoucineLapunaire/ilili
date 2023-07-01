import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ilili/components/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference usersCollection = firestore.collection('users');
FirebaseAuth auth = FirebaseAuth.instance;
GoogleSignIn googleSignIn = GoogleSignIn();
bool termOfUses = false;

class SignupPage extends StatelessWidget {
  SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: SingleChildScrollView(
              child: Container(
        height: MediaQuery.of(context).size.height,
        width: double.maxFinite,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [
            Color(0xFF6A1B9A),
            Color(0xFFCD7CFF),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        )),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LogoSection(),
            SizedBox(height: 20),
            TitleSection(),
            SizedBox(height: 20),
            FormSection(),
            SizedBox(height: 10),
            ToLogin(),
            Divider(
              color: Colors.white,
              height: 20,
              thickness: 2,
            ),
            GoogleSignupForm(),
          ],
        ),
      ))),
    );
  }
}

class LogoSection extends StatelessWidget {
  LogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(
          image: AssetImage('assets/images/logo.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class TitleSection extends StatelessWidget {
  const TitleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("ilili",
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        SizedBox(width: 10),
        Text("signup",
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFF009688))),
      ],
    );
  }
}

class FormSection extends StatefulWidget {
  FormSection({super.key});

  @override
  _FormSectionState createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSection> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmationController =
      TextEditingController();
  bool passwordSame = false;
  bool error = false;
  String errorMessage = "";
  String infoMessage = "";

  Future<void> signup() async {
    if (emailController.text == '' ||
        passwordController.text == '' ||
        passwordConfirmationController.text == '') {
      setState(() {
        error = true;
        errorMessage = "All fields must be filled";
      });
      return;
    }
    if (termOfUses == false) {
      setState(() {
        error = true;
        errorMessage = "You must accept the terms of use";
      });
      return;
    }
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      User? user = userCredential.user;

      String uid = userCredential.user?.uid ?? '';

      await firestore.collection('users').doc(uid).set({
        'pseudo': '',
        'profilPicture': '',
      });

      print('User signed up and document created successfully!');
      setState(() {
        error = false;
        errorMessage = "";
        infoMessage = "User signed up successfully!";
      });
    } catch (e) {
      print('Error signing up user and creating document: $e');
      setState(() {
        error = true;
        errorMessage = e.toString().split('] ')[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      child: Column(
        children: [
          if (error)
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 5),
                  Container(
                    width: 250,
                    child: Text(
                      "${errorMessage}",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          if (infoMessage != '')
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 5),
                  Container(
                    width: 250,
                    child: Text(
                      "${infoMessage}",
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
          SizedBox(height: 10),
          TextField(
            obscureText: true,
            controller: passwordController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.lock),
              labelText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            obscureText: true,
            controller: passwordConfirmationController,
            onChanged: (value) {
              if (passwordController.text == value) {
                setState(() {
                  passwordSame = false;
                });
              } else {
                setState(() {
                  passwordSame = true;
                });
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.lock),
              labelText: 'Password Confirmation',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SizedBox(height: 10),
          if (passwordSame)
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 5),
                  Container(
                    width: 250,
                    child: Text(
                      'Password and password confirmation must be the same',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          Row(
            children: [
              Checkbox(
                activeColor: Colors.white,
                checkColor: Color(0xFF6A1B9A),
                value: termOfUses,
                onChanged: (value) {
                  setState(() {
                    termOfUses = value!;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      termOfUses = !termOfUses;
                    });
                  },
                  child: Text(
                    'I have read and agree to the Terms of Use and Privacy Policy',
                    style: TextStyle(
                        decoration:
                            termOfUses ? TextDecoration.lineThrough : null,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              signup();
            },
            child: Text('Signup'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              fixedSize:
                  Size(200, 50), // Set the width and height of the button
              backgroundColor:
                  Color(0xFF009688), // Set the background color of the button
            ),
          ),
        ],
      ),
    );
  }
}

class ToLogin extends StatelessWidget {
  const ToLogin({super.key});

  void redirectToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        redirectToLogin(context);
      },
      child: Text("Already have an account? Login"),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
            Colors.transparent), // Set the background color to transparent
        elevation: MaterialStateProperty.all<double>(
            0), // Remove the button's elevation
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                8), // Customize the button's border radius as desired
            side: BorderSide(
                color: Colors.transparent), // Remove the button's border
          ),
        ),
      ),
    );
  }
}

class GoogleSignupForm extends StatefulWidget {
  const GoogleSignupForm({Key? key}) : super(key: key);

  @override
  _GoogleSignupFormState createState() => _GoogleSignupFormState();
}

class _GoogleSignupFormState extends State<GoogleSignupForm> {
  String errorMessage = '';

  verifyTermsOfUses() {
    if (termOfUses) {
      setState(() {
        errorMessage = '';
      });
      signupWithGoogle();
    } else {
      setState(() {
        errorMessage = 'You must agree to the terms of uses';
      });
      return;
    }
  }

  Future<void> signupWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() {
        errorMessage = e.toString().split('] ')[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (errorMessage != '')
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 5),
                Container(
                  width: 250,
                  child: Text(
                    "${errorMessage}",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        Container(
          width: 250,
          child: ElevatedButton(
            onPressed: () {
              verifyTermsOfUses();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors
                  .white, // Set button background color // Set button text color
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(30), // Set button border radius
              ),
              padding: EdgeInsets.symmetric(
                  vertical: 10, horizontal: 16), // Set button padding
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google.png', // Replace with the path to your Google icon image
                  height: 20, // Set the height of the icon
                ),
                SizedBox(
                    width: 10), // Add some spacing between the icon and text
                Text(
                  'Signup with Google',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black), // Set the font size of the text
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
