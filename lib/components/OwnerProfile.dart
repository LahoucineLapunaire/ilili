import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/settings.dart';
import 'package:Ilili/components/widget.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

class OwnerProfilePage extends StatelessWidget {
  const OwnerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: SingleChildScrollView(
          child: Center(
              child: Column(
            children: [
              SizedBox(
                height: 30,
              ),
              DelayedDisplay(
                delay: Duration(microseconds: 500),
                child: TopSection(),
              ),
              DelayedDisplay(
                delay: Duration(microseconds: 800),
                child: PostSection(),
              ),
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
  List<dynamic> followers = [];
  List<dynamic> followings = [];
  bool isPictureLoad = false;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // This function retrieves user data from Firestore and updates the state
  void getUserData() async {
    // Use Firestore to fetch the user's document based on their UID
    DocumentSnapshot ds =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    // Update the app's state with the retrieved user data
    setState(() {
      // Extract the user's username from the document
      username = ds.get('username');

      // Extract the user's profile picture URL from the document
      profilPicture = ds.get('profilePicture');

      // Set a flag to indicate that the user's profile picture has been loaded
      isPictureLoad = true;

      // Extract the user's description from the document
      description = ds.get('description');

      // Extract the user's followers count from the document
      followers = ds.get('followers');

      // Extract the user's followings count from the document
      followings = ds.get('followings');
    });
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
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                onPressed: () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  } catch (e) {
                    print("Error: ${e.toString()}");
                  }
                },
              ),
              const SizedBox(
                width: 10,
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return const FollowersListModal();
                    },
                  );
                },
                child: Column(
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
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return const FollowingsListModal();
                    },
                  );
                },
                child: Column(
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

  // Function to retrieve posts from Firestore for the currently logged-in user
  void getPosts() async {
    // Query Firestore to get posts where the 'userId' matches the current user's ID
    QuerySnapshot<Map<String, dynamic>> qs = await FirebaseFirestore.instance
        .collection('posts')
        .where("userId", isEqualTo: auth.currentUser!.uid)
        .get();

    // Create an empty list to store post data
    List<Map<dynamic, dynamic>> postslist = qs.docs.map((doc) {
      // Extract the 'timestamp' field from Firestore document
      Timestamp timestamp = doc.get('timestamp');
      double newTimestamp = timestamp.seconds.toDouble();

      // Return a map with 'id' and 'timestamp' for each post
      return {
        "id": doc.id,
        "timestamp": newTimestamp,
      };
    }).toList();

    // Sort the list of posts based on the 'timestamp' in descending order
    postslist.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));

    // Set the 'posts' state variable with a list of post IDs
    setState(() {
      posts = postslist.map((e) => e["id"]).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return posts.isEmpty
        ? Container(
            height: 200,
            child: const Center(
              child: Text(
                "No posts yet, to add a post, please go to the add Post page",
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
                  userId: auth.currentUser!.uid,
                  isOwner: true,
                  inPostPage: false,
                ),
            ],
          );
  }
}
