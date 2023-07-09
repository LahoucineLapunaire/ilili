import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/changeProfile.dart';
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Open the popup menu when the floating action button is pressed
            showPopupMenu(context);
          },
          child: Icon(Icons.add),
        ),
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

void showPopupMenu(BuildContext context) {
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  final double yOffset =
      -230; // Adjust the y-offset value to move the menu higher

  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(button.size.bottomRight(Offset.zero),
          ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero),
          ancestor: overlay),
    ).translate(0, yOffset), // Apply the y-offset to move the menu higher
    Offset.zero & overlay.size,
  );

  // Create and show the popup menu
  showMenu(
    context: context,
    position: position,
    items: [
      PopupMenuItem(
        child: Text('User Account'),
        value: 'User Account',
      ),
      PopupMenuItem(
        child: Text('Settings'),
        value: 'Settings',
      ),
    ],
    elevation: 8,
  ).then((selectedValue) {
    if (selectedValue == "User Account") {
      // Do something based on the selected value
      print('Selected value: $selectedValue');
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => ChangeProfilePage()));
    }
  });
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
