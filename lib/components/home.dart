import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/UserProfilePage.dart';
import 'package:ilili/components/changeProfile.dart';
import 'package:ilili/components/messageList.dart';
import 'package:ilili/components/setUsername.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ilili/components/widget.dart';

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
  TextEditingController textEditingController = TextEditingController();
  late CollectionReference<Map<String, dynamic>> usersCollectionRef;
  List<dynamic> posts = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkUsername();
    getFeedPosts();
    setState(() {
      usersCollectionRef = firestore.collection('users');
    });
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
      if (mounted) {
        setState(() {
          userInfo['username'] = ds.get('username');
          userInfo['profilPicture'] = ds.get('profilePicture');
        });
      }
    }
  }

  Future<void> getFeedPosts() async {
    try {
      // Retrieve the Firestore posts collection
      CollectionReference<Map<String, dynamic>> postsCollectionRef =
          firestore.collection('posts');

      // Query the posts collection and order by weighted score
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await postsCollectionRef.get();

      // Extract the post documents and convert them to Post objects with weighted score
      List<Post> postslist = querySnapshot.docs.map((doc) {
        String user = doc.get('userId');
        int score = doc.get('score');
        Timestamp timestamp = doc.get('timestamp');
        double weightedScore =
            score.toDouble() * 0.7 + timestamp.seconds.toDouble() * 0.3;

        return Post(
          userId: user,
          postId: doc.id,
          weightedScore: weightedScore,
          // Add other properties as per your Post class definition
        );
      }).toList();

      // Sort the posts based on weighted score
      postslist.sort((a, b) => b.weightedScore.compareTo(a.weightedScore));

      setState(() {
        posts = postslist;
      });
      return;
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Search"),
          backgroundColor: Color(0xFF6A1B9A),
          actions: [
            IconButton(
              onPressed: () {
                showSearch(
                    context: context,
                    delegate: SearchDelegateWidget(usersCollectionRef));
              },
              icon: Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MessageListPage()));
              },
              icon: Icon(Icons.message),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: posts.length == 0
                ? Container(
                    height: 200,
                    child: Center(
                      child: Text(
                        "No posts yet, please follow users to see their posts.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (Post post in posts)
                        AudioPlayerWidget(
                          postId: post.postId,
                          userId: post.userId,
                          isOwner: false,
                        ),
                    ],
                  ),
          ),
        ));
  }
}

class Post {
  final String postId;
  final String userId;
  final double weightedScore;

  Post({
    required this.weightedScore,
    required this.userId,
    required this.postId,
  });
}

class SearchDelegateWidget extends SearchDelegate {
  final CollectionReference<Map<String, dynamic>> usersCollectionRef;

  SearchDelegateWidget(this.usersCollectionRef);

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if (query.isEmpty) {
            close(context, null);
          }
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: usersCollectionRef
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final searchResults = snapshot.data!.docs;
          return ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final document = searchResults[index];
              return ListTile(
                title: Text(document['username']),
                onTap: () {
                  close(context, document['username']);
                },
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error occurred while searching.'),
          );
        } else {
          return Center(
            child: Text('No search results found.'),
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container(); // Return an empty container when the query is empty
    }

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: usersCollectionRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final users = snapshot.data!.docs;
          List<User> suggestion = users
              .map((document) {
                return User(
                  userId: document.id,
                  username: document['username'] as String,
                  profilePicture: document['profilePicture'] as String,
                );
              })
              .where((user) =>
                  user.username.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return ListView.builder(
            itemCount: suggestion.length,
            itemBuilder: (context, index) {
              User user = suggestion[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user.profilePicture),
                ),
                title: Text(user.username),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            UserProfilePage(userId: user.userId)),
                  );
                },
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error occurred while fetching users.'),
          );
        } else {
          return Center(
            child: Text('No users found.'),
          );
        }
      },
    );
  }
}

class User {
  final String username;
  final String profilePicture;
  final String userId;

  User(
      {required this.username,
      required this.profilePicture,
      required this.userId});
}
