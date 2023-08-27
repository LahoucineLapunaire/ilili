import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/changeProfile.dart';
import 'package:Ilili/components/chat.dart';
import 'package:Ilili/components/floattingButton.dart';
import 'package:Ilili/components/notification.dart';
import 'package:Ilili/components/widget.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

class UserProfilePage extends StatelessWidget {
  final String userId;

  const UserProfilePage({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 30,
              ),
              DelayedDisplay(
                child: TopSection(userId: userId),
                delay: Duration(microseconds: 500),
              ),
              DelayedDisplay(
                child: PostSection(userId: userId),
                delay: Duration(microseconds: 800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopSection extends StatefulWidget {
  final String userId;
  const TopSection({super.key, required this.userId});

  @override
  State<TopSection> createState() => _TopSectionState();
}

class _TopSectionState extends State<TopSection> {
  String username = "";
  String profilPicture =
      'https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=8aa7825f-2890-4f63-9fb2-e66e7e916256';
  String description = "";
  List<dynamic> followers = [];
  List<dynamic> followings = [];
  String myUsername = "";
  String myProfilePicture = "";
  bool isPictureLoad = false;

  @override
  void initState() {
    super.initState();
    getUserData();
    getMyInfo();
  }

  void follow() async {
    if (followers.contains(auth.currentUser!.uid)) {
      firestore.collection('users').doc(widget.userId).update({
        'followers': FieldValue.arrayRemove([auth.currentUser!.uid])
      });
      firestore.collection('users').doc(auth.currentUser!.uid).update({
        'following': FieldValue.arrayRemove([widget.userId])
      });
      setState(() {
        followers.remove(auth.currentUser!.uid);
      });
    } else {
      firestore.collection('users').doc(widget.userId).update({
        'followers': FieldValue.arrayUnion([auth.currentUser!.uid])
      });
      firestore.collection('users').doc(auth.currentUser!.uid).update({
        'followings': FieldValue.arrayUnion([widget.userId])
      });
      setState(() {
        followers.add(auth.currentUser!.uid);
      });
      sendNotificationToTopic("${widget.userId}", "New followers",
          "$myUsername started to following you", myProfilePicture, {
        "sender": auth.currentUser!.uid,
        "receiver": widget.userId,
        "type": "follow",
        "click_action": "FLUTTER_FOLLOW_CLICK",
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getUserData() async {
    DocumentSnapshot ds =
        await firestore.collection('users').doc(widget.userId).get();

    setState(() {
      username = ds.get('username');
      profilPicture = ds.get('profilePicture');
      description = ds.get('description');
      followers = ds.get('followers');
      followings = ds.get('followings');
      isPictureLoad = true;
    });
  }

  void getMyInfo() async {
    DocumentSnapshot ds =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    setState(() {
      myProfilePicture = ds.get('profilePicture');
      myUsername = ds.get('username');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFFCD7CFF),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              offset: const Offset(
                0.0,
                5.0,
              ),
              blurRadius: 5.0,
            )
          ]),
      child: Column(
        children: [
          SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    "${followers.length}",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "followers",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                height: 120,
                width: 120,
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
                child: isPictureLoad
                    ? SizedBox(
                        height: 30,
                        width: 30,
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(profilPicture),
                        ),
                      )
                    : Center(
                        child: CircularProgressIndicator(
                          color: Colors.grey,
                        ),
                      ),
              ),
              Column(
                children: [
                  Text(
                    "${followings.length}",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "followings",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            "$username",
            style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Text(
              "$description",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  follow();
                },
                style: followers.contains(auth.currentUser!.uid)
                    ? ElevatedButton.styleFrom(
                        side: BorderSide(color: Colors.white),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: Size(75, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      )
                    : ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: Size(75, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                child: Text(
                  followers.contains(auth.currentUser!.uid)
                      ? "Unfollow"
                      : "Follow",
                ),
              ),
              SizedBox(width: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatPage(
                              userId: widget.userId,
                              username: username,
                              profilePicture: profilePicture,
                            )),
                  );
                },
                style: ElevatedButton.styleFrom(
                  side: BorderSide(color: Colors.white),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: Size(75, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  "Message",
                ),
              )
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class PostSection extends StatefulWidget {
  final String userId;
  const PostSection({super.key, required this.userId});

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
        .where("userId", isEqualTo: widget.userId)
        .get();

    setState(() {
      posts = qs.docs.map((e) => e.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return posts.length == 0
        ? Container(
            height: 200,
            child: Center(
              child: Text(
                "No posts yet",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : ListView(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            children: [
              for (var post in posts)
                AudioPlayerWidget(
                  postId: post,
                  userId: widget.userId,
                  isOwner: widget.userId == auth.currentUser!.uid,
                  inPostPage: false,
                ),
            ],
          );
  }
}
