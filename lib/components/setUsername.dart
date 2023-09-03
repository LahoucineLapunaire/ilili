import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/appRouter.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class SetUsernamePage extends StatefulWidget {
  const SetUsernamePage({super.key});

  @override
  State<SetUsernamePage> createState() => _SetUsernamePageState();
}

class _SetUsernamePageState extends State<SetUsernamePage> {
  TextEditingController usernameController = TextEditingController();
  List<String> usernameList = [];
  String error = "";

  @override
  void initState() {
    super.initState();
    getAllUsername();
  }

  // This function retrieves all usernames from the Firestore database and populates usernameList.
  Future<void> getAllUsername() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection("users").get();

    // Loop through the retrieved documents and add usernames to usernameList.
    for (int i = 0; i < querySnapshot.docs.length; i++) {
      usernameList.add(querySnapshot.docs[i].get('username'));
    }
  }

// Check if a given string contains spaces or special characters using regular expressions.
  bool containsSpacesOrSpecialCharacters(String input) {
    RegExp regex = RegExp(r'[^\w,]'); // Define a regular expression pattern.
    return regex
        .hasMatch(input); // Check if the pattern matches any part of the input.
  }

// Check the validity of a username.
  bool checkUsername() {
    if (usernameList.contains(usernameController.text.toLowerCase())) {
      setState(
        () {
          error =
              "Username already exists"; // Display an error message if the username already exists.
        },
      );
      return false;
    }
    if (containsSpacesOrSpecialCharacters(usernameController.text)) {
      setState(
        () {
          error =
              "Username cannot contain spaces or special characters"; // Display an error message for invalid characters.
        },
      );
      return false;
    }
    if (usernameController.text.length > 20) {
      setState(
        () {
          error =
              "Username cannot be more than 20 characters"; // Display an error message for a username that's too long.
        },
      );
      return false;
    }
    setState(
      () {
        error = ""; // Clear any previous error messages.
      },
    );
    return true; // Username is valid.
  }

// Set the username in Firestore if it passes validation.
  Future<void> setUsername() async {
    if (checkUsername()) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(auth.currentUser!.uid)
          .update({
        "username": usernameController.text.toLowerCase()
      }); // Update the username in Firestore.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AppRouter(index: 2),
        ),
      ); // Navigate to the specified route.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: WillPopScope(
      onWillPop: () async {
        print("Back Pressed");
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TextTop(),
            const SizedBox(height: 30),
            Container(
              width: 300,
              child: TextField(
                controller: usernameController,
                onChanged: (value) {
                  checkUsername();
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person),
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            if (error != "")
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 5),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setUsername();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                minimumSize: const Size(250, 50),
              ),
              child: const Text(
                "Set My Username",
              ),
            )
          ],
        ),
      ),
    ));
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
              "What's your username?",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Please enter your username below.",
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
