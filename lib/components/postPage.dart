import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/widget.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mailer/mailer.dart';

String sortType = "newest";
List<dynamic> commentList = [];

FirebaseFirestore firestore = FirebaseFirestore.instance;

class PostPage extends StatefulWidget {
  final String postId;
  final String userId;
  final bool isOwner;

  PostPage(
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

  Future<void> getComments() async {
    try {
      List<dynamic> result = [];
      final postSnapshot =
          await firestore.collection('posts').doc(widget.postId).get();
      final comments = postSnapshot.data()?['comments'];
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
      result.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
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
        backgroundColor: Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Color(0xFFFAFAFA),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
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
              icon: Icon(Icons.refresh, color: Colors.black),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0xFF6A1B9A),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return CommentModal(
                  postId: widget.postId,
                );
              },
            );
          },
          child: Icon(Icons.comment),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                AudioPlayerWidget(
                  postId: widget.postId,
                  userId: widget.userId,
                  isOwner: widget.isOwner,
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
                        return CircularProgressIndicator(
                          color: Colors.grey,
                        );
                      } else {
                        return CommentSection();
                      }
                    })
              ],
            ),
          ),
        ));
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
    widget
        .onSortChanged(result); // Call the callback function with updated list
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Text("Sort by: "),
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
      ),
    );
  }
}

class CommentSection extends StatefulWidget {
  const CommentSection({super.key});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return commentList.length == 0
        ? Container(
            height: 200,
            child: Center(
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

  void initState() {
    super.initState();
    getComment();
    getUser();
  }

  getComment() {
    try {
      bool _isLiked = false;
      firestore
          .collection('comments')
          .doc(widget.commentId)
          .get()
          .then((postSnapshot) {
        if (postSnapshot.data()?['likes'].contains(auth.currentUser!.uid)) {
          _isLiked = true;
        }
        setState(() {
          comment = postSnapshot.data()?['comment'];
          timestamp = postSnapshot.data()?['timestamp'];
          likes = postSnapshot.data()?['likes'];
          isLiked = _isLiked;
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

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

  likeComment() {
    try {
      if (isLiked) {
        firestore.collection('comments').doc(widget.commentId).update({
          "likes": FieldValue.arrayRemove([auth.currentUser!.uid]),
          "score": FieldValue.increment(-1)
        });
        setState(() {
          likes.remove(auth.currentUser!.uid);
        });
      } else {
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

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();

    String formattedDate = '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.year.toString().substring(2)}';

    String formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';

    return '$formattedDate $formattedTime';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
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
                          height: 0,
                          width: 40,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(profilePicture),
                          ),
                        )
                      : Center(
                          child: CircularProgressIndicator(
                            color: Colors.grey,
                          ),
                        ),
                  SizedBox(width: 10),
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
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
                  PopupMenuItem(
                    value: 'Report Comment',
                    child: Text('Report Comment'),
                    textStyle: TextStyle(color: Colors.black),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                comment,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Opacity(
                opacity: 0.6,
                child: Text(formatTimestamp(timestamp)),
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
          )
        ],
      ),
    );
  }
}
