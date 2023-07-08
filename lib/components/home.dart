import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/setUsername.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> userInfo = {
    "username": "",
    "profilPicture": "",
  };

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkUsername();
  }

  Future<void> checkUsername() async {
    DocumentSnapshot ds =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    if (ds.exists == false ||
        ds.get('username') == "" ||
        ds.get('username') == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SetUsernamePage()));
    } else {
      setState(() {
        userInfo['username'] = ds.get('username');
        userInfo['profilPicture'] = ds.get('profilePicture');
      });
    }
  }

  void logout() {
    auth.signOut().then((value) => print("User logged out"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Welcome ${userInfo["username"]}!"),
          Text("${auth.currentUser!.email}"),
          Text("${auth.currentUser!.uid}"),
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
