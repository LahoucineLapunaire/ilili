import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ilili/components/appRouter.dart';
import 'package:ilili/components/widget.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class SetUsernamePage extends StatefulWidget {
  const SetUsernamePage({super.key});

  @override
  State<SetUsernamePage> createState() => _SetUsernamePageState();
}

class _SetUsernamePageState extends State<SetUsernamePage> {
  TextEditingController usernameController = TextEditingController();
  List<String> usernameList = [];

  @override
  void initState() {
    super.initState();
    getAllUsername();
  }

  Future<void> getAllUsername() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection("users").get();

    for (int i = 0; i < querySnapshot.docs.length; i++) {
      usernameList.add(querySnapshot.docs[i].get('username'));
      print("Username: ${querySnapshot.docs[i].get('username')}");
      ;
    }
  }

  bool containsSpacesOrSpecialCharacters(String input) {
    RegExp regex = RegExp(r'[^\w,]');
    return regex.hasMatch(input);
  }

  bool checkUsername() {
    if (usernameList.contains(usernameController.text)) {
      showErrorMessage("Username already exists", context);
      return false;
    }
    if (containsSpacesOrSpecialCharacters(usernameController.text)) {
      showErrorMessage(
          "Username cannot contain spaces or special characters", context);
      return false;
    }
    if (usernameController.text.length > 20) {
      showErrorMessage("Username cannot be longer than 20 characters", context);
      return false;
    }
    return true;
  }

  Future<void> setUsername() async {
    if (checkUsername()) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(auth.currentUser!.uid)
          .update({"username": usernameController.text.toLowerCase()});
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppRouter(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextTop(),
          SizedBox(height: 30),
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
                prefixIcon: Icon(Icons.person),
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              setUsername();
            },
            child: Text(
              "Set My Username",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A1B9A),
              minimumSize: Size(250, 50),
            ),
          )
        ],
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
          padding: EdgeInsets.only(left: 20),
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
