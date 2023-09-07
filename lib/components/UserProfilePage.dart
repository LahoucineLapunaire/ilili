import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/chat.dart';
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 30,
              ),
              DelayedDisplay(
                delay: const Duration(microseconds: 500),
                child: TopSection(userId: userId),
              ),
              DelayedDisplay(
                delay: const Duration(microseconds: 800),
                child: PostSection(userId: userId),
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

  // This function allows the user to follow or unfollow another user.
  void follow() async {
    if (followers.contains(auth.currentUser!.uid)) {
      // If the user is already following, unfollow them.
      await firestore.collection('users').doc(widget.userId).update({
        'followers': FieldValue.arrayRemove([auth.currentUser!.uid])
      });
      await firestore.collection('users').doc(auth.currentUser!.uid).update({
        'following': FieldValue.arrayRemove([widget.userId])
      });
      setState(() {
        followers.remove(auth.currentUser!.uid);
      });
    } else {
      // If the user is not following, follow them.
      await firestore.collection('users').doc(widget.userId).update({
        'followers': FieldValue.arrayUnion([auth.currentUser!.uid])
      });
      await firestore.collection('users').doc(auth.currentUser!.uid).update({
        'followings': FieldValue.arrayUnion([widget.userId])
      });
      setState(() {
        followers.add(auth.currentUser!.uid);
      });

      // Send a notification to the user being followed.
      sendNotificationToTopic(widget.userId, "New followers",
          "$myUsername started to following you", myProfilePicture, {
        "sender": auth.currentUser!.uid,
        "receiver": widget.userId,
        "type": "follow",
        "click_action": "FLUTTER_FOLLOW_CLICK",
      });
    }
  }

// This function retrieves data of the user being viewed.
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

// This function retrieves the current user's information.
  void getMyInfo() async {
    DocumentSnapshot ds =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    setState(() {
      myProfilePicture = ds.get('profilePicture');
      myUsername = ds.get('username');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
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
              offset: Offset(
                0.0,
                5.0,
              ),
              blurRadius: 5.0,
            )
          ]),
      child: Column(
        children: [
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    "${followers.length}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
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
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.grey,
                        ),
                      ),
              ),
              Column(
                children: [
                  Text(
                    "${followings.length}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
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
          const SizedBox(height: 10),
          Text(
            username,
            style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Text(
              description,
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  follow();
                },
                style: followers.contains(auth.currentUser!.uid)
                    ? ElevatedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(75, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      )
                    : ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(75, 40),
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
              const SizedBox(width: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatPage(
                              userId: widget.userId,
                              username: username,
                              profilePicture: profilPicture,
                            )),
                  );
                },
                style: ElevatedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(75, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  "Message",
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return posts.isEmpty
        ? Container(
            height: 200,
            child: const Center(
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
            physics: const ClampingScrollPhysics(),
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
