import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/resetPassword.dart';
import 'package:Ilili/components/signup.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Ilili/components/widget.dart';

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
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DelayedDisplay(
                delay: Duration(milliseconds: 500), child: HeaderSection()),
            SizedBox(height: 50),
            DelayedDisplay(
                delay: Duration(milliseconds: 800), child: FormSection()),
            SizedBox(height: 20),
            DelayedDisplay(
                delay: Duration(milliseconds: 1000), child: ToSignup()),
            DelayedDisplay(
                delay: Duration(milliseconds: 1000),
                child: ToForgottedPassword()),
            DelayedDisplay(
                delay: Duration(milliseconds: 1000),
                child: Divider(
                  height: 20,
                  thickness: 2,
                )),
            DelayedDisplay(
                delay: Duration(milliseconds: 1200), child: GoogleLoginForm()),
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
      padding: const EdgeInsets.only(left: 20),
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
  const FormSection({super.key});

  @override
  _FormSectionState createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSection> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool obscureText = true;

  void login() async {
    try {
      // Check if email and password fields are empty
      if (emailController.text == '' || passwordController.text == '') {
        showErrorMessage("All fields must be filled", context);
        return;
      }

      // Attempt to sign in with the provided email and password
      await auth
          .signInWithEmailAndPassword(
              email: emailController.text, password: passwordController.text)
          .then((value) {
        // If successful, print a success message
        print("User ${value.user?.email} logged in");
      });
    } catch (e) {
      if (mounted) {
        // Check the error message to determine the specific error
        if (e.toString().split('] ')[1] ==
            "There is no user record corresponding to this identifier. The user may have been deleted.") {
          showErrorMessage("User not found", context);
          return;
        } else {
          // If there is an error, print the error message and display it to the user
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
                  const SizedBox(height: 5),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.email),
                      labelText: 'Enter your email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 20),
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
                  const SizedBox(height: 5),
                  TextField(
                    obscureText: obscureText,
                    controller: passwordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock),
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
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              minimumSize: const Size(250, 50),
            ),
            onPressed: () => login(),
            child: const Text("Login"),
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
              MaterialPageRoute(builder: (context) => const SignupPage()),
            ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(250, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: const Row(
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
          MaterialPageRoute(builder: (context) => const ResetPassword()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        minimumSize: const Size(250, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: const Text(
        "password forgotten ?",
        style: TextStyle(color: Colors.black),
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
      // Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId:
            "593268336010-9o5us0954qr95sqrbmcl6j57dm4keib1.apps.googleusercontent.com", // Replace with your Google OAuth2 client ID
      ).signIn();

      print(googleUser);

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

        // Check if the user already exists in Firestore
        final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userSnapshot.exists) {
          // User already exists, log in and navigate to HomePage
          // Add your own navigation logic here
          print('User already exists');
          // Example navigation to HomePage:
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => HomePage()),
          // );
        } else {
          // User does not exist, create a new document in Firestore
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'profilePicture':
                'YOUR_DEFAULT_PROFILE_IMAGE_URL_HERE', // Replace with your default profile image URL
            'username': '',
            'posts': [],
            'followers': [],
            'followings': [],
            'chats': [],
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
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 16), // Set button padding
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google.png', // Replace with the path to your Google icon image
                  height: 20, // Set the height of the icon
                ),
                const SizedBox(
                    width: 10), // Add some spacing between the icon and text
                const Text(
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
