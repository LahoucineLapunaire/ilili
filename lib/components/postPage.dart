import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/widget.dart';
import 'package:intl/intl.dart';

import 'appRouter.dart';

String sortType = "newest";
List<dynamic> commentList = [];

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

class PostPage extends StatefulWidget {
  final String postId;
  final String userId;
  final bool isOwner;

  const PostPage(
      {super.key,
      required this.postId,
      required this.userId,
      required this.isOwner});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  late Future<void> _getCommentsFuture;

  @override
  void initState() {
    _getCommentsFuture = getComments();
    super.initState();
  }

// Function to fetch comments for a post
  Future<void> getComments() async {
    try {
      List<dynamic> result = [];
      // Fetch the post data
      final postSnapshot =
          await firestore.collection('posts').doc(widget.postId).get();
      final comments = postSnapshot.data()?['comments'];

      // Loop through the comments and fetch details for each comment
      for (String comment in comments) {
        final postSnapshot =
            await firestore.collection('comments').doc(comment).get();
        result.add({
          "commentId": comment,
          "timestamp": postSnapshot.data()?['timestamp'],
          "likes": postSnapshot.data()?['likes'],
          "userId": postSnapshot.data()?['userId'],
        });
      }

      // Sort the comments by timestamp in descending order
      result.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      // Update the commentList in the state
      setState(() {
        commentList = result;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void dispose() {
    commentList = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFAFA),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppRouter(index: 0),
                  ));
            },
          ),
          title: Text(
            "Post Page",
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  commentList = [];
                });
                getComments();
              },
              icon: const Icon(Icons.refresh, color: Colors.black),
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: WillPopScope(
          onWillPop: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppRouter(index: 0),
                ));
            return Future.value(false);
          },
          child: Center(
            child: Column(
              children: [
                AudioPlayerWidget(
                  postId: widget.postId,
                  userId: widget.userId,
                  isOwner: widget.isOwner,
                  inPostPage: true,
                ),
                SortSection(
                  onSortChanged: (sortedComments) {
                    setState(() {
                      commentList = sortedComments;
                    });
                  },
                ),
                FutureBuilder<void>(
                    future: _getCommentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(
                          color: Colors.grey,
                        );
                      } else {
                        return const CommentSection();
                      }
                    })
              ],
            ),
          ),
        )));
  }
}

class SortSection extends StatefulWidget {
  final Function(List<dynamic>) onSortChanged;

  const SortSection({super.key, required this.onSortChanged});

  @override
  State<SortSection> createState() => _SortSectionState();
}

class _SortSectionState extends State<SortSection> {
  String sortType = "newest"; // Make sure this is declared here

// Function to sort comments based on the selected criteria
  void sortComments(sortType) {
    List<dynamic> result = commentList;

    if (sortType == "newest") {
      result.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    } else if (sortType == "oldest") {
      result.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    } else if (sortType == "most liked") {
      result.sort((a, b) => b['likes'].length.compareTo(a['likes'].length));
    } else if (sortType == "least liked") {
      result.sort((a, b) => a['likes'].length.compareTo(b['likes'].length));
    }

    // Call the callback function with the updated list
    widget.onSortChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text("Sort by: "),
        DropdownButton<String>(
          value: sortType,
          icon: const Icon(Icons.arrow_downward),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(color: Colors.deepPurple),
          underline: Container(
            height: 2,
            color: Colors.deepPurpleAccent,
          ),
          onChanged: (String? newValue) {
            setState(() {
              sortType = newValue!;
            });
            sortComments(newValue);
          },
          items: <String>['newest', 'oldest', 'most liked', 'least liked']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        )
      ],
    );
  }
}

class CommentSection extends StatefulWidget {
  const CommentSection({super.key});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return commentList.isEmpty
        ? Container(
            height: 200,
            child: const Center(
              child: Text(
                "No comment yet.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : Column(
            children: [
              for (var comment in commentList)
                if (comment != null)
                  CommentWidget(
                      commentId: comment["commentId"],
                      userId: comment["userId"])
            ],
          );
  }
}

class CommentWidget extends StatefulWidget {
  final String commentId;
  final String userId;

  const CommentWidget(
      {super.key, required this.commentId, required this.userId});

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  String username = "";
  String profilePicture =
      "https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=db72d8e7-aa9d-4b64-886c-549987962cb2";
  String comment = "";
  List<dynamic> likes = [];
  Timestamp timestamp = Timestamp.now();
  bool isLiked = false;
  String email = "";
  String reportReason = "";
  bool isPictureLoaded = false;

  @override
  void initState() {
    super.initState();
    getComment();
    getUser();
  }

// Function to fetch details of a single comment
  getComment() {
    try {
      bool isLiked = false;
      firestore
          .collection('comments')
          .doc(widget.commentId)
          .get()
          .then((postSnapshot) {
        if (postSnapshot.data()?['likes'].contains(auth.currentUser!.uid)) {
          isLiked = true;
        }
        setState(() {
          comment = postSnapshot.data()?['comment'];
          timestamp = postSnapshot.data()?['timestamp'];
          likes = postSnapshot.data()?['likes'];
          isLiked = isLiked;
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

// Function to fetch user details associated with a comment
  getUser() {
    try {
      firestore
          .collection('users')
          .doc(widget.userId)
          .get()
          .then((postSnapshot) {
        setState(() {
          username = postSnapshot.data()?['username'];
          profilePicture = postSnapshot.data()?['profilePicture'];
          isPictureLoaded = true;
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

// Function to handle liking/unliking a comment
  likeComment() {
    try {
      if (isLiked) {
        // Unlike the comment
        firestore.collection('comments').doc(widget.commentId).update({
          "likes": FieldValue.arrayRemove([auth.currentUser!.uid]),
          "score": FieldValue.increment(-1)
        });
        setState(() {
          likes.remove(auth.currentUser!.uid);
        });
      } else {
        // Like the comment
        setState(() {
          likes.add(auth.currentUser!.uid);
        });
        firestore.collection('comments').doc(widget.commentId).update({
          "likes": FieldValue.arrayUnion([auth.currentUser!.uid]),
          "score": FieldValue.increment(1)
        });
      }
      setState(() {
        isLiked = !isLiked;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Function to format timestamp into a readable format
  String formatTimestamp(Timestamp timestamp) {
    final maintenant = Timestamp.now();
    final difference = maintenant.seconds - timestamp.seconds;

    if (difference < 60) {
      return '$difference sec';
    } else if (difference < 60 * 60) {
      return '${difference ~/ 60} min';
    } else if (difference < 60 * 60 * 24) {
      return '${difference ~/ (60 * 60)} h';
    } else if (difference < 60 * 60 * 24 * 7) {
      return '${difference ~/ (60 * 60 * 24)} j';
    } else if (difference < 60 * 60 * 24 * 30) {
      final dateTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);
      return DateFormat('MM/dd/yyyy', 'en_US')
          .format(dateTime); // American format
    } else {
      final dateTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);
      return DateFormat('MM/dd/yyyy', 'en_US')
          .format(dateTime); // American format for months
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  isPictureLoaded
                      ? SizedBox(
                          height: 40,
                          width: 40,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(profilePicture),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Colors.grey,
                          ),
                        ),
                  const SizedBox(width: 10),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Opacity(
                    opacity: 0.6,
                    child: Text(formatTimestamp(timestamp)),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (String value) {
                  // Handle menu item selection
                  if (value == "Report Comment") {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return ReportModal(
                          isPost: false,
                          reportId: widget.commentId,
                          username: username,
                          userId: widget.userId,
                          title: "",
                          content: comment,
                        );
                      },
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'Report Comment',
                    textStyle: TextStyle(color: Colors.black),
                    child: Text('Report Comment'),
                  ),
                ],
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 50,
                  ),
                  Text(
                    comment,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(likes.length.toString()),
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: isLiked ? Colors.red : null,
                    ),
                    onPressed: () {
                      likeComment();
                    },
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
