import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ilili/components/widget.dart';

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
        appBar: AppBar(
          backgroundColor: Color(0xFF6A1B9A),
          title: Text("Post"),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  commentList = [];
                });
                getComments();
              },
              icon: Icon(Icons.refresh),
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
                SortSection(),
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
  const SortSection({super.key});

  @override
  State<SortSection> createState() => _SortSectionState();
}

void sortComments(sortType) {
  if (sortType == "newest") {
    commentList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
  } else if (sortType == "oldest") {
    commentList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
  } else if (sortType == "most liked") {
    commentList.sort((a, b) => b['likes'].compareTo(a['likes']));
  } else if (sortType == "least liked") {
    commentList.sort((a, b) => a['likes'].compareTo(b['likes']));
  }
}

class _SortSectionState extends State<SortSection> {
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
    ;
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
          "likes": FieldValue.arrayRemove([auth.currentUser!.uid])
        });
        setState(() {
          likes.remove(auth.currentUser!.uid);
        });
      } else {
        setState(() {
          likes.add(auth.currentUser!.uid);
        });
        firestore.collection('comments').doc(widget.commentId).update({
          "likes": FieldValue.arrayUnion([auth.currentUser!.uid])
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
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.black,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40.0),
                child: Image.network(
                  profilePicture, // Replace with the actual path and filename of your image file
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
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
