import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            gradient: LinearGradient(
          colors: [
            Color(0xFF6A1B9A),
            Color(0xFFCD7CFF),
          ],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        )),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LogoSection(),
            SizedBox(height: 20),
            TitleSection(),
            SizedBox(height: 20),
            FormSection(),
            SizedBox(height: 20),
            ToSignup(),
            ToForgottedPassword(),
            Divider(
              color: Colors.white,
              height: 20,
              thickness: 2,
            ),
            GoogleLoginForm(),
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
          image: AssetImage('assets/images/ic_launcher.png'),
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
                fontSize: 50,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        SizedBox(width: 10),
        Text("login",
            style: TextStyle(
                fontSize: 50,
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
          ElevatedButton(
            onPressed: () {
              login();
            },
            child: Text('Login'),
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

class ToSignup extends StatelessWidget {
  const ToSignup({super.key});

  void redirectToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        redirectToLogin(context);
      },
      child: Text("No account ? Register now "),
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

class ToForgottedPassword extends StatelessWidget {
  const ToForgottedPassword({super.key});

  void redirectToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResetPassword()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        redirectToLogin(context);
      },
      child: Text("password forgotten ?"),
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
