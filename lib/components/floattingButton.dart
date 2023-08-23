import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Ilili/components/changeProfile.dart';
import 'package:Ilili/components/chat.dart';
import 'package:Ilili/components/settings.dart';
import 'package:Ilili/components/widget.dart';

import 'notification.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
FirebaseAuth auth = FirebaseAuth.instance;

class FloatingActionButtonOwner extends StatefulWidget {
  FloatingActionButtonOwner({Key? key}) : super(key: key);

  @override
  _FloatingActionButtonOwnerState createState() =>
      _FloatingActionButtonOwnerState();
}

class _FloatingActionButtonOwnerState extends State<FloatingActionButtonOwner> {
  bool isOpen = false;

  void toggleMenu() {
    setState(() {
      isOpen = !isOpen;
    });
  }

  void logout() {
    auth.signOut().then((value) => print("User logged out"));
  }

  void showPopupMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final double yOffset =
        -175; // Adjust the y-offset value to move the menu higher

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ).translate(0, yOffset), // Apply the y-offset to move the menu higher
      Offset.zero & overlay.size,
    );

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
        PopupMenuItem(
          child: Text(
            'Logout',
            style: TextStyle(color: Colors.red),
          ),
          value: 'Logout',
        ),
      ],
      elevation: 8,
    ).then((selectedValue) {
      if (selectedValue == "User Account") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChangeProfilePage()),
        );
      } else if (selectedValue == "Settings") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
      } else if (selectedValue == "Logout") {
        logout();
      }
      toggleMenu();
    }).whenComplete(() {
      setState(() {
        isOpen = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        if (isOpen) {
          // Handle close button action here
          print('Close button pressed');
        } else {
          // Open the popup menu when the floating action button is pressed
          showPopupMenu(context);
        }
        toggleMenu();
      },
      backgroundColor: Color(0xFF6A1B9A),
      child: isOpen ? Icon(Icons.close) : Icon(Icons.menu),
    );
  }
}

class FloatingActionButtonUser extends StatefulWidget {
  final String ownerId;

  FloatingActionButtonUser({Key? key, required this.ownerId}) : super(key: key);

  @override
  _FloatingActionButtonUserState createState() =>
      _FloatingActionButtonUserState();
}

class _FloatingActionButtonUserState extends State<FloatingActionButtonUser> {
  bool isOpen = false;
  List<dynamic> followingList = [];
  String username = "";
  String profilePicture = "";
  String myusername = "";

  @override
  void initState() {
    getUsersInformations();
    super.initState();
  }

  void toggleMenu() {
    setState(() {
      isOpen = !isOpen;
    });
  }

  void getUsersInformations() async {
    firestore
        .collection('users')
        .doc(widget.ownerId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          followingList = documentSnapshot['followers'];
          username = documentSnapshot['username'];
          profilePicture = documentSnapshot['profilePicture'];
        });
      }
    });
    firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          myusername = documentSnapshot['username'];
        });
      }
    });
  }

  void follow() async {
    if (followingList.contains(auth.currentUser!.uid)) {
      firestore.collection('users').doc(widget.ownerId).update({
        'followers': FieldValue.arrayRemove([auth.currentUser!.uid])
      });
      firestore.collection('users').doc(auth.currentUser!.uid).update({
        'following': FieldValue.arrayRemove([widget.ownerId])
      });
      setState(() {
        followingList.remove(auth.currentUser!.uid);
      });
    } else {
      firestore.collection('users').doc(widget.ownerId).update({
        'followers': FieldValue.arrayUnion([auth.currentUser!.uid])
      });
      firestore.collection('users').doc(auth.currentUser!.uid).update({
        'followings': FieldValue.arrayUnion([widget.ownerId])
      });
      setState(() {
        followingList.add(auth.currentUser!.uid);
      });
      sendNotificationToTopic(
          "follow", "New followers", "$myusername started to following you", {
        "sender": auth.currentUser!.uid,
        "receiver": widget.ownerId,
        "type": "follow",
        "click_action": "FLUTTER_FOLLOW_CLICK",
      });
    }
  }

  void showPopupMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final double yOffset =
        -175; // Adjust the y-offset value to move the menu higher

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ).translate(0, yOffset), // Apply the y-offset to move the menu higher
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          child: followingList.contains(auth.currentUser!.uid)
              ? Text('Unfollow')
              : Text('Follow'),
          value: 'Follow',
        ),
        PopupMenuItem(
          child: Text('Message'),
          value: 'Message',
        ),
      ],
      elevation: 8,
    ).then((selectedValue) {
      if (selectedValue == "Follow") {
        print('Selected value: $selectedValue');
        follow();
      }
      if (selectedValue == "Message") {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatPage(
                    userId: widget.ownerId,
                    username: username,
                    profilePicture: profilePicture,
                  )),
        );
      }
      toggleMenu();
    }).whenComplete(() {
      setState(() {
        isOpen = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        if (isOpen) {
          // Handle close button action here
          print('Close button pressed');
        } else {
          // Open the popup menu when the floating action button is pressed
          showPopupMenu(context);
        }
        toggleMenu();
      },
      backgroundColor: Color(0xFF6A1B9A),
      child: isOpen ? Icon(Icons.close) : Icon(Icons.menu),
    );
  }
}

class FloatingActionButtonUserMessage extends StatefulWidget {
  const FloatingActionButtonUserMessage({super.key});

  @override
  State<FloatingActionButtonUserMessage> createState() =>
      _FloatingActionButtonUserMessageState();
}

class _FloatingActionButtonUserMessageState
    extends State<FloatingActionButtonUserMessage> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Color(0xFF6A1B9A),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return UsersListModal();
          },
        );
      },
      child: Icon(Icons.add),
    );
  }
}
