import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ilili/components/resetPassword.dart';
import 'package:ilili/components/signup.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ilili/components/widget.dart';

GoogleSignIn googleSignIn = GoogleSignIn();

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: SingleChildScrollView(
              child: Container(
        height: MediaQuery.of(context).size.height,
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: Color(0xFFFAFAFA),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DelayedDisplay(
                child: HeaderSection(), delay: Duration(milliseconds: 500)),
            SizedBox(height: 50),
            DelayedDisplay(
                child: FormSection(), delay: Duration(milliseconds: 800)),
            SizedBox(height: 20),
            DelayedDisplay(
                child: ToSignup(), delay: Duration(milliseconds: 1000)),
            DelayedDisplay(
                child: ToForgottedPassword(),
                delay: Duration(milliseconds: 1000)),
            DelayedDisplay(
                child: Divider(
                  height: 20,
                  thickness: 2,
                ),
                delay: Duration(milliseconds: 1000)),
            DelayedDisplay(
                child: GoogleLoginForm(), delay: Duration(milliseconds: 1200)),
          ],
        ),
      ))),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20),
      width: double.maxFinite,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "Hey, Welcome back !",
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Hello again, you have been missed !",
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        )
      ]),
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
  bool obscureText = true;

  void login() async {
    try {
      if (emailController.text == '' || passwordController.text == '') {
        showErrorMessage("All fields must be filled", context);
        return;
      }
      await auth
          .signInWithEmailAndPassword(
              email: emailController.text, password: passwordController.text)
          .then((value) => {print("User ${value.user?.email} logged in")});
    } catch (e) {
      if (mounted) {
        if (e.toString().split('] ')[1] ==
            "There is no user record corresponding to this identifier. The user may have been deleted.") {
          showErrorMessage("User not found", context);
          return;
        } else {
          print("Error : $e");
          showErrorMessage(e.toString().split('] ')[1], context);
        }
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      child: Column(
        children: [
          Container(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Email Address",
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.email),
                      labelText: 'Enter your email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              )),
          SizedBox(height: 20),
          Container(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Password",
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    obscureText: obscureText,
                    controller: passwordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                      labelText: 'Enter your password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              )),
          SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A1B9A),
              minimumSize: Size(250, 50),
            ),
            onPressed: () => login(),
            child: Text("Login"),
          ),
        ],
      ),
    );
  }
}

class ToSignup extends StatelessWidget {
  const ToSignup({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupPage()),
            ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: Size(250, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account ?",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            SizedBox(width: 5),
            Text(
              "Sign Up",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ));
  }
}

class ToForgottedPassword extends StatelessWidget {
  const ToForgottedPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResetPassword()),
        );
      },
      child: Text(
        "password forgotten ?",
        style: TextStyle(color: Colors.black),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        minimumSize: Size(250, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}

class GoogleLoginForm extends StatefulWidget {
  const GoogleLoginForm({Key? key}) : super(key: key);

  @override
  _GoogleLoginFormState createState() => _GoogleLoginFormState();
}

class _GoogleLoginFormState extends State<GoogleLoginForm> {
  Future<void> signupWithGoogle() async {
    try {
      print("Signing up with Google");
      // Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser != null) {
        // Obtain the authentication details from the Google sign-in
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential using the Google ID token and access token
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        final String uid = userCredential.user!.uid;

        // Check if the user already exists
        final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userSnapshot.exists) {
          // User already exists, log in and navigate to HomePage
          // Add your own navigation logic here
          print('User already exists');
          // Navigate to HomePage
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => HomePage()),
          // );
        } else {
          // User does not exist, create a new document in Firestore
          await firestore.collection('users').doc(uid).set({
            'profilePicture':
                'https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=8aa7825f-2890-4f63-9fb2-e66e7e916256',
            'username': '',
            'posts': [],
            'followers': [],
            'following': [],
            'description': '',
          });

          print('New user created');

          // Add your own navigation logic here to navigate to the desired page after sign-up
        }
      }
    } catch (e) {
      print("----------------> Error : ${e.toString()}");
      showErrorMessage(e.toString().split('] ')[1], context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 250,
          child: ElevatedButton(
            onPressed: () {
              signupWithGoogle();
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
                  'Login with Google',
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
