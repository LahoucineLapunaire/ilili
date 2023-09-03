import 'package:Ilili/components/appRouter.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Ilili/components/UserProfilePage.dart';
import 'package:Ilili/components/messageList.dart';
import 'package:Ilili/components/setUsername.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Ilili/components/widget.dart';

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
  int unreadMessages = 0;
  TextEditingController textEditingController = TextEditingController();
  late CollectionReference<Map<String, dynamic>> usersCollectionRef;
  List<dynamic> posts = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkUsername();
    getFeedPosts();
    getNumbersLastMessage();
    setState(() {
      usersCollectionRef = firestore.collection('users');
    });
  }

  Future<void> checkUsername() async {
    // Fetch the user document from Firestore based on the current user's UID
    DocumentSnapshot ds =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    // Check if the document exists or if the username field is empty or null
    if (ds.exists == false ||
        ds.get('username') == "" ||
        ds.get('username') == null) {
      // If any of the conditions are met, navigate to the SetUsernamePage
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SetUsernamePage()));
    } else {
      // If conditions are not met, update the userInfo state with the fetched data
      if (mounted) {
        setState(() {
          userInfo['username'] = ds.get('username');
          userInfo['profilPicture'] = ds.get('profilePicture');
        });
      }
    }
  }

  void getNumbersLastMessage() async {
    // Fetch the user document again for this function
    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    // Initialize variables to keep track of unread messages and chat IDs
    int _unreadMessages = 0;
    List<String> chats = List<String>.from(userDoc['chats']);

    // Iterate through chat IDs and get the last message for each chat
    for (String chatId in chats) {
      QuerySnapshot<Map<String, dynamic>> chatSnapshot = await firestore
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection(chatId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // Check if the last message is unread and update the unread message count
      if (chatSnapshot.docs.isNotEmpty) {
        if (!chatSnapshot.docs.first['read']) {
          _unreadMessages++;
        }
      }

      // Update the unreadMessages state if the component is still mounted
      if (mounted) {
        setState(() {
          unreadMessages = _unreadMessages;
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

  void redirectToAddPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppRouter(index: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.purple.withOpacity(0.1),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            redirectToAddPost(context);
          },
          child: Icon(Icons.add, color: Colors.white),
          backgroundColor: Color(0xFF6A1B9A),
        ),
        appBar: AppBar(
          backgroundColor: Color(0xFFFAFAFA),
          title: SizedBox(
            height: 40,
            width: 40,
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/ic_launcher.png'),
            ),
          ),
          centerTitle: true,
          actions: [
            unreadMessages == 0
                ? IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MessageListPage()));
                    },
                    icon: Icon(
                      Icons.message,
                      color: Colors.black,
                    ),
                  )
                : Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MessageListPage()));
                        },
                        icon: Icon(Icons.message, color: Colors.black),
                      ),
                      if (unreadMessages > 0)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Text(
                              unreadMessages.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ],
        ),
        body: SingleChildScrollView(
            child: DelayedDisplay(
          delay: Duration(milliseconds: 300),
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
                          isOwner: post.userId == auth.currentUser!.uid,
                          inPostPage: false,
                        ),
                      SizedBox(height: 100),
                    ],
                  ),
          ),
        )));
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
          List<UserHome> suggestion = users
              .map((document) {
                return UserHome(
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
              UserHome user = suggestion[index];
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

class UserHome {
  final String username;
  final String profilePicture;
  final String userId;

  UserHome(
      {required this.username,
      required this.profilePicture,
      required this.userId});
}
