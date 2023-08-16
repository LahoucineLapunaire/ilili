import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:ilili/components/changeProfile.dart';
import 'package:ilili/components/chat.dart';
import 'package:ilili/components/widget.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';

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
      sendNotificationToTopic();
      firestore.collection('users').doc(widget.ownerId).update({
        'followers': FieldValue.arrayUnion([auth.currentUser!.uid])
      });
      firestore.collection('users').doc(auth.currentUser!.uid).update({
        'followings': FieldValue.arrayUnion([widget.ownerId])
      });
      setState(() {
        followingList.add(auth.currentUser!.uid);
      });
    }
  }

  Future<void> sendNotificationToTopic() async {
    var credential = await obtainCredentials().then((value) {
      return value.accessToken.data as String;
    });
    final String fcmEndpoint =
        'https://fcm.googleapis.com/v1/projects/ilili-7ebc6/messages:send?key=AIzaSyDWjIzP1Fn3dHcbWCOs1WVf6lFBlcQIYgE';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $credential',
    };

    final data = {
      "message": {
        "topic": "follow",
        "notification": {
          "title": "New Follower",
          "body": "$username started following you",
        },
        "data": {"story_id": "story_12345"}
      }
    };

    final response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification. Response: ${response.body}');
    }
  }

  Future<AccessCredentials> obtainCredentials() async {
    var accountCredentials = ServiceAccountCredentials.fromJson({
      "private_key_id": "edbeba145ad68e0a47dbe51faca57b2068b0b703",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCSDT6A4V7i6cnr\nK4SoqDZL8qwAt5zxbiguT6jHTu14e+grEJsozL36YmF2KMiALh7icjRgTW+sBtyq\n85lbPP3suuzgd3s7lxMIGtVNSfcJlzPd4dnTICeh4QS32rltijmnC8SiD/m9XzTQ\nQsFwTAZWKBYA5xLtu23/Ri23Kxhr01s1GBjec/X0pa6g+WIMhe74bV1v0Dp8Qd2M\ndItIxC77r5M7E0du/R1h/NcILTQaQm/1FAi8NJCoal38+KuT48Q15t2BqjuaGxYa\n7aV3aj4kJYH9rQbpd6WN05dJE00IH5wvlWjYPZlErM1OnePOkga5eFKvzB2Y24vy\nSP86P1uhAgMBAAECggEADZTyt4x9xO9FyjtRSlfeOMDX8vcgPqlmTiw1P1edKMOp\nCvwv2aL0lci5VIIlZxoi4B8LtNrupBo9Qh6GJ+BroqydY6Bo0tlROUM5i8bxlLA9\ncAhVN9d5KAojZK+P59pfUyP6hLGkoVItuKJEl9tSCYgPx8S1U2tHJuKRVMPKsRgi\nH4h8ORh60EiMTNPDTei2VaDRMk9BTcszLQZUyYz+YTqbwPPI70V8tel75WuYONhI\nDHKTRKkHbfsPEX9hSC8vnJyHtpLRohKA/kIRvA7uI1QjgR8dyo0P+4n+VASOik45\nvanIlSpjdAAJ0uyqvz4bi0mh5dBWse2G7akQCACwWwKBgQDDcnumecNzZa2DIG2b\na6vdJI0gERiUgEVEL7tfCGl3DVVNvgU2KVqJb+Gts+Lq1HleYYnfbLhZPDHu1tVQ\nslBwb6MAcT28k4yl0g5C0Dwn5xWaOLSYEUX1DPFrD+CGDyb22HduCXOSwFb1UYTr\neRK6pZeTh007X60Viy6actSoXwKBgQC/TQ4qNEUmGB8wbAYcNNsmy31TOnKxN/hG\nGUNLIU0BuYK+e0oDczFf/Vr0R+YpPwsgShwOldotl9fcx6ZbbK07YMZcFUuI1p9y\nqv5tbAeqO4nPpcbOwY87vv0wBkBCKIKGjiSLDi0RhuXi9Bvcd6dLg9XGjaerlaV4\nDde5Ojp7/wKBgEfC/jGm3aO+PpI50uTRCN5+sC6I+Gx2GHiryfFfxlGHHL4ZuhIj\n5vE1mjhMJ1Ivx4xm5deaNKnXF0JpsRMbFbvi0Ye1DITz7B1qXgAcMyo3h9ADaBO5\nq+UI5o932el/IMBbxKYrZDsK0iLq1pIa90x+xoPNlwbo30VcwDTHWtujAoGAVkC6\n60KIDwX/QgjitGMMkLBdQGJxBgCTW5/WXJCWNPncvl++XlHY6EvGb6/fUaeQL63a\neqUMK1R0SqJmGoCklsoqhahAV2FVoRECCHoV9qZDm7FGM0DIgQq7A6U94dZ8C4kZ\nZu0sWuO00SB5U21Lq9u0ToLeH5oocjnjkyty5ScCgYBXfGAqx5OwyDe0L2N7e6ku\n+CUq0OrsOEVpbXFBpawpPdH82rFyWXb5RZT2VLTMWDd+vz7wmiMN3pABQidNmL5q\nTslmLZ7iudmaI3YDAFAK0ww9NccuEs4DFqC2IbotAezXsznDr0eZd7L7kWz6DI9e\nIKlvVFVuE2CYcm+L45Qomg==\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-l17m2@ilili-7ebc6.iam.gserviceaccount.com",
      "client_id": "109835428077305918471",
      "type": "service_account"
    });
    var scopes = [
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    var client = http.Client();
    AccessCredentials credentials =
        await obtainAccessCredentialsViaServiceAccount(
            accountCredentials, scopes, client);

    client.close();
    return credentials;
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
