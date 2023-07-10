import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/changeProfile.dart';
import 'package:ilili/components/widget.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFECEFF1),
        floatingActionButton: FloatingActionButtonUser(),
        body: SingleChildScrollView(
          child: Center(
              child: Column(
            children: [
              SizedBox(height: 30),
              TopSection(),
              PostSection(),
            ],
          )),
        ));
  }
}

class TopSection extends StatefulWidget {
  const TopSection({super.key});

  @override
  State<TopSection> createState() => _TopSectionState();
}

class _TopSectionState extends State<TopSection> {
  String username = "";
  String profilPicture =
      'https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=8aa7825f-2890-4f63-9fb2-e66e7e916256';
  String description = "";
  int followers = 0;
  int following = 0;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getUserData() async {
    DocumentSnapshot ds =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    setState(() {
      username = ds.get('username');
      profilPicture = ds.get('profilePicture');
      description = ds.get('description');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3), // changes the position of the shadow
            ),
          ],
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFFCD7CFF),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          )),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(75),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: Image.network(
                "$profilPicture",
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            "$username",
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Text(
              "$description",
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              "$followers followers",
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10),
            Text(
              "$following following",
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 20)
          ]),
          SizedBox(height: 25),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    getPosts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getPosts() async {
    QuerySnapshot<Map<String, dynamic>> qs = await FirebaseFirestore.instance
        .collection('posts')
        .where("userId", isEqualTo: auth.currentUser!.uid)
        .get();

    setState(() {
      posts = qs.docs.map((e) => e.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      children: [
        for (var post in posts)
          AudioPlayerWidget(postId: post, userId: auth.currentUser!.uid),
      ],
    );
  }
}
