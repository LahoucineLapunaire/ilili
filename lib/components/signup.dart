import 'package:delayed_display/delayed_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:Ilili/components/widget.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference usersCollection = firestore.collection('users');
FirebaseAuth auth = FirebaseAuth.instance;
GoogleSignIn googleSignIn = GoogleSignIn();
bool termOfUses = false;

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Center(
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
            SizedBox(height: 10),
            DelayedDisplay(
                delay: Duration(milliseconds: 1000), child: ToLogin()),
            DelayedDisplay(
                delay: Duration(milliseconds: 1400),
                child: Divider(
                  height: 10,
                  thickness: 2,
                )),
            DelayedDisplay(
                delay: Duration(milliseconds: 1000), child: GoogleSignupForm()),
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
          "Create Account",
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Connect and share today !",
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
  TextEditingController passwordConfirmationController =
      TextEditingController();
  bool passwordSame = false;
  String passwordStrength = "";
  bool obscureText = true;

  // Function to send email verification
  Future<void> sendEmailVerification() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      // Check if user is not null and email is not verified
      if (user != null && !user.emailVerified) {
        // Send email verification
        await user.sendEmailVerification();
        showInfoMessage('Email verification sent to ${user.email}', context,
            () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        });
        print('Email verification sent to ${user.email}');
      } else {
        // User is null or email is already verified
        showErrorMessage('No user or email is already verified', context);
        print('No user or email is already verified');
      }
    } catch (e) {
      if (mounted) {
        // Handle errors and show error message
        showErrorMessage(e.toString(), context);
      }
    }
  }

// Function to sign up user
  Future<void> signup() async {
    // Check if required fields are empty
    if (emailController.text == '' ||
        passwordController.text == '' ||
        passwordConfirmationController.text == '') {
      showErrorMessage("All fields must be filled", context);
      return;
    }

    // Check if terms of use are accepted
    if (termOfUses == false) {
      showErrorMessage("You must accept the terms of use", context);
      return;
    }

    // Check if passwords match
    if (passwordController.text != passwordConfirmationController.text) {
      showErrorMessage("Passwords must be the same", context);
      return;
    }

    // Check password strength
    if (passwordStrength != "") {
      showErrorMessage("Password must be strong", context);
      return;
    }

    try {
      // Create user with email and password
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Get user's UID
      String uid = userCredential.user?.uid ?? '';

      // Create a document for the user
      await firestore.collection('users').doc(uid).set({
        'profilePicture':
            'https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=8aa7825f-2890-4f63-9fb2-e66e7e916256',
        'username': '',
        'posts': [],
        'followers': [],
        'followings': [],
        'chats': [],
        'description': '',
      });

      print('User signed up and document created successfully!');

      // Send email verification
      sendEmailVerification();

      // Show success message
      showInfoMessage("User signed up successfully!", context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
    } catch (e) {
      print('Error signing up user and creating document: $e');
      if (mounted) {
        // Handle errors and show error message
        showErrorMessage(e.toString().split('] ')[1], context);
      }
    }
  }

// Function to verify password strength
  void verifyStrongPassword() {
    bool lenght = passwordController.text.length >= 8;
    bool upperCase = passwordController.text.contains(RegExp(r'[A-Z]'));
    bool specialChar =
        passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool number = passwordController.text.contains(RegExp(r'[0-9]'));
    String message = "";

    // Check password strength requirements
    if (!lenght || !upperCase || !specialChar || !number) {
      message = "Please enter a password that contains : ";
    }
    if (!lenght) {
      message += "\nat least 8 characters, ";
    }
    if (!upperCase) {
      message += "\nat least one uppercase letter, ";
    }
    if (!specialChar) {
      message += "\nat least one special character, ";
    }
    if (!number) {
      message += "\nat least one number, ";
    }

    setState(() {
      passwordStrength = message;
    });
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
                    onChanged: (value) {
                      verifyStrongPassword();
                    },
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
          if (passwordStrength != '')
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 5),
                  Container(
                    width: 250,
                    child: Text(
                      "$passwordStrength",
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          const SizedBox(height: 20),
          Container(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Password Confirmation",
                    style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    obscureText: obscureText,
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
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock),
                      labelText: 'Enter your password again',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 10),
          if (passwordSame)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 5),
                  Container(
                    width: 250,
                    child: const Text(
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
                checkColor: const Color(0xFF6A1B9A),
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
                        color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              minimumSize: const Size(250, 50),
            ),
            onPressed: () => signup(),
            child: const Text("Join Now !"),
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
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () => redirectToLogin(context),
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
              "Already an account ?",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            SizedBox(width: 5),
            Text(
              "Login",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ));
  }
}

class GoogleSignupForm extends StatefulWidget {
  const GoogleSignupForm({Key? key}) : super(key: key);

  @override
  _GoogleSignupFormState createState() => _GoogleSignupFormState();
}

class _GoogleSignupFormState extends State<GoogleSignupForm> {
  verifyTermsOfUses() {
    if (termOfUses) {
      signupWithGoogle();
    } else {
      showErrorMessage('You must agree to the terms of uses', context);
      return;
    }
  }

  Future<void> signupWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
              clientId:
                  "593268336010-9o5us0954qr95sqrbmcl6j57dm4keib1.apps.googleusercontent.com")
          .signIn();
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
        } else {
          // User does not exist, create a new document in Firestore
          await firestore.collection('users').doc(uid).set({
            'profilePicture':
                'https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=8aa7825f-2890-4f63-9fb2-e66e7e916256',
            'username': '',
            'posts': [],
            'followers': [],
            'followings': [],
            'chats': [],
            'description': 'mydescription',
            'subscription': false,
          }).then((value) {
            print("User added");
          });
        }
      }
    } catch (e) {
      print("error signing up with google: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 250,
          height: 50,
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
