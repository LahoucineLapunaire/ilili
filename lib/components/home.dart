import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth auth = FirebaseAuth.instance;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void logout() {
    auth.signOut().then((value) => print("User logged out"));
  }

  void testVerifiedAccount() {
    if (auth.currentUser!.emailVerified) {
      print("User is verified");
    } else {
      print("User is not verified");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    testVerifiedAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ButtonLogout(),
        ],
      ),
    ));
  }
}

class ButtonLogout extends StatelessWidget {
  const ButtonLogout({super.key});

  void logout() {
    auth.signOut().then((value) => print("User logged out"));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        onPressed: () {
          logout();
        },
        child: Text('Logout'),
      ),
    );
  }
}
