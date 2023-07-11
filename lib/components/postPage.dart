import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ilili/components/widget.dart';

String sortType = "newest";
List<dynamic> commentList = [];

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
  @override
  void initState() {
    super.initState();
    print("post page init");
    getComments();
  }

  void getComments() async {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((event) {
      event.docs.forEach((element) {
        commentList.add(element);
      });
    });
    print(commentList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Post"),
        ),
        floatingActionButton: FloatingActionButton(
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
        body: Center(
          child: Column(
            children: [
              AudioPlayerWidget(
                postId: widget.postId,
                userId: widget.userId,
                isOwner: widget.isOwner,
                isComment: false,
              ),
              SortSection(),
              CommentSection(),
            ],
          ),
        ));
  }
}

class SortSection extends StatefulWidget {
  const SortSection({super.key});

  @override
  State<SortSection> createState() => _SortSectionState();
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
              setState(() {
                sortType = newValue!;
              });
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var comment in commentList)
          AudioPlayerWidget(
            postId: comment['postId'],
            userId: comment['userId'],
            isOwner: comment['isOwner'],
            isComment: true,
          ),
      ],
    );
  }
}
