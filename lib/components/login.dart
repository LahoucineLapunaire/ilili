import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/resetPassword.dart';
import 'package:ilili/components/signup.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignIn googleSignIn = GoogleSignIn();

FirebaseAuth auth = FirebaseAuth.instance;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
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
      )),
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
  bool error = false;
  String errorMessage = "";

  void login() async {
    if (emailController.text == '' || passwordController.text == '') {
      setState(() {
        error = true;
        errorMessage = "All fields must be filled";
      });
      return;
    }
    try {
      await auth
          .signInWithEmailAndPassword(
              email: emailController.text, password: passwordController.text)
          .then((value) => {print("User ${value.user?.email} logged in")});
      setState(() {
        error = false;
        errorMessage = "";
      });
    } catch (e) {
      setState(() {
        error = true;
        errorMessage = e.toString().split('] ')[1];
      });
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
