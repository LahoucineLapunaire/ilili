import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/component.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      body: Center(
          child: Column(
        children: [
          SizedBox(height: 30),
          TopSection(),
          SizedBox(height: 10),
          Divider(
            color: Colors.black,
            height: 20,
            thickness: 2,
            indent: 20,
            endIndent: 20,
          ),
          PostSection(),
        ],
      )),
    );
  }
}

class TopSection extends StatefulWidget {
  const TopSection({super.key});

  @override
  State<TopSection> createState() => _TopSectionState();
}

class _TopSectionState extends State<TopSection> {
  String username = "";
  String profilPicture = "";
  String description = "";
  int followers = 0;
  int following = 0;

  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    DocumentSnapshot ds =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    setState(() {
      username = ds.get('username');
      profilPicture = ds.get('profilPicture');
      description = ds.get('description');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                    width: 80,
                    height: 80,
                    child: Icon(Icons.account_circle, size: 80)),
                Text("$username"),
              ],
            ),
            PopupMenuButton<String>(onSelected: (value) {
              // Handle the sub-menu item selection
              print('Selected: $value');
            }, itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'User Profile',
                  child: Text('User Profile'),
                ),
                PopupMenuItem<String>(
                  value: 'Parameters',
                  child: Text('Parameters'),
                ),
              ];
            })
          ],
        ),
        Text("$description"),
        SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text("$followers followers"),
          SizedBox(width: 10),
          Text("$following following"),
          SizedBox(width: 20)
        ]),
      ],
    );
  }
}

class PostSection extends StatefulWidget {
  const PostSection({super.key});

  @override
  State<PostSection> createState() => _PostSectionState();
}

class _PostSectionState extends State<PostSection> {
  List<dynamic> posts = [];

  void initState() {
    super.initState();
    getPosts();
  }

  void getPosts() async {
    QuerySnapshot<Map<String, dynamic>> qs = await FirebaseFirestore.instance
        .collection('posts')
        .where("userId", isEqualTo: auth.currentUser!.uid)
        .get();

    setState(() {
      posts = qs.docs.map((e) => e.get('audio')).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [for (var post in posts) AudioPlayerWidget(audioPath: post)],
    );
  }
}
