import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ilili/components/UserProfilePage.dart';
import 'package:ilili/components/appRouter.dart';
import 'package:ilili/components/changeProfile.dart';
import 'package:ilili/components/OwnerProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/chat.dart';
import 'package:ilili/components/postPage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as path;

FirebaseFirestore firestore = FirebaseFirestore.instance;
Reference storageRef = FirebaseStorage.instance.ref("comments");
FirebaseAuth auth = FirebaseAuth.instance;

class AudioPlayerWidget extends StatefulWidget {
  final String userId;
  final String postId;
  bool isOwner = false;

  AudioPlayerWidget({
    Key? key,
    required this.userId,
    required this.postId,
    required this.isOwner,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration audioDuration = Duration();
  Duration position = Duration();
  String audioPath = '';
  String profilePicture =
      "https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=8aa7825f-2890-4f63-9fb2-e66e7e916256";
  String username = '';
  String postDate = '';
  List<dynamic> tags = [];
  List<dynamic> likes = [];
  List<dynamic> comments = [];
  bool shouldReload = false;

  @override
  void initState() {
    super.initState();
    getUserInfo();
    getPostInfo();
  }

  void reloadPage() {
    setState(() {
      // Set the flag to trigger a rebuild of the widget
      shouldReload = true;
    });
  }

  void getUserInfo() async {
    DocumentSnapshot<Map<String, dynamic>> ds =
        await firestore.collection('users').doc(widget.userId).get();
    setState(() {
      profilePicture = ds.data()!['profilePicture'];
      username = ds.data()!['username'];
    });
  }

  void getPostInfo() async {
    DocumentSnapshot<Map<String, dynamic>> ds =
        await firestore.collection('posts').doc(widget.postId).get();
    setState(() {
      audioPath = ds.data()!['audio'];
      tags = ds.data()!['tags'];
      likes = ds.data()!['likes'];
      comments = ds.data()!['comments'];
      postDate = formatTimestamp(ds.data()!['timestamp']);
    });
    audioPlayer.setSourceUrl(audioPath);
    audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        audioDuration = duration;
      });
      audioPlayer.onPositionChanged.listen((Duration pos) {
        setState(() {
          position = pos;
        });
      });
    });
  }

  Future<void> playPause() async {
    try {
      if (isPlaying) {
        await audioPlayer.pause();
        setState(() => isPlaying = false);
      } else {
        if (audioPath != null) {
          await audioPlayer.play(UrlSource(audioPath)).then((value) {});
          setState(() => isPlaying = true);
        }
      }
    } catch (e) {
      setState(() {
        print('Error: $e');
      });
    }
  }

  Future<void> likePost() async {
    try {
      if (likes.contains(auth.currentUser!.uid)) {
        await firestore.collection('posts').doc(widget.postId).update({
          'likes': FieldValue.arrayRemove([auth.currentUser!.uid])
        });
        setState(() {
          likes.remove(auth.currentUser!.uid);
        });
      } else {
        await firestore.collection('posts').doc(widget.postId).update({
          'likes': FieldValue.arrayUnion([auth.currentUser!.uid])
        });
        setState(() {
          likes.add(auth.currentUser!.uid);
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _seekToSecond(int second) {
    Duration newDuration = Duration(seconds: second);
    audioPlayer.seek(newDuration);
  }

  String formatPosition(int position) {
    double result = position / 1000;
    String minutes = (result / 60).floor().toString().padLeft(2, '0');
    String seconds = (result % 60).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds';
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

  void deletePost() async {
    try {
      // Delete the file in Firebase Storage
      if (audioPath.isNotEmpty) {
        Reference storageReference =
            FirebaseStorage.instance.refFromURL(audioPath);
        await storageReference.delete();
      }
      for (String comment in comments) {
        await firestore.collection('comments').doc(comment).delete();
      }
      // Delete the post document in Firestore
      await firestore.collection('posts').doc(widget.postId).delete();
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => AppRouter()));
      dispose();
    } catch (e) {
      print("Error: $e");
    }
  }

  void openModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ChangeTagsModal(
          idPost: widget.postId,
        );
      },
    );
  }

  void redirectToUser() {
    if (widget.isOwner) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => OwnerProfilePage()));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => UserProfilePage(
                    userId: widget.userId,
                  )));
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose(); // Dispose of the audio player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  redirectToUser(); // Call the redirectToUser() function on tap
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40.0),
                      child: Image.network(
                        profilePicture, // Replace with the actual path and filename of your image file
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isOwner)
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    // Handle menu item selection
                    if (value == "Modify Post") {
                      openModal(context);
                    } else if (value == "Delete Post") {
                      deletePost();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'Modify Post',
                      child: Text('Modify Post'),
                      textStyle: TextStyle(color: Colors.black),
                    ),
                    PopupMenuItem(
                      value: 'Delete Post',
                      child: Text('Delete Post'),
                      textStyle: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  playPause();
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(formatPosition(position.inMilliseconds)),
                  Slider(
                    activeColor: Color(0xFF6A1B9A),
                    inactiveColor: Color(0xFF6A1B9A).withOpacity(0.3),
                    min: 0.0,
                    max: audioDuration.inSeconds.toDouble(),
                    value: position.inSeconds
                        .toDouble()
                        .clamp(0.0, audioDuration.inSeconds.toDouble()),
                    onChanged: (double value) {
                      setState(() {
                        _seekToSecond(value.toInt());
                      });
                    },
                  ),
                  Text(formatPosition(audioDuration.inMilliseconds)),
                ],
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var tag in tags)
                Container(
                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                  decoration: BoxDecoration(
                    color: Color(0xFF009688),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: Offset(0,
                            2), // Controls the shadow position, positive value for bottom
                        blurRadius:
                            2, // Determines the blurriness of the shadow
                        spreadRadius: 0, // Controls the spread of the shadow
                      ),
                    ],
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Opacity(
                    opacity: 0.6,
                    child: Text(postDate),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(likes.length.toString()),
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: likes.contains(auth.currentUser?.uid)
                          ? Colors.red
                          : null,
                    ),
                    onPressed: () {
                      if (widget.isOwner) {
                        print("likes: $likes");
                      } else {
                        likePost();
                      }
                    },
                  ),
                  SizedBox(width: 5),
                  Visibility(
                    child: Row(
                      children: [
                        Text(comments.length.toString()),
                        IconButton(
                          icon: Icon(Icons.comment),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostPage(
                                  postId: widget.postId,
                                  userId: widget.userId,
                                  isOwner: widget.isOwner,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class ChangeTagsModal extends StatefulWidget {
  final String idPost;

  ChangeTagsModal({Key? key, required this.idPost}) : super(key: key);

  @override
  State<ChangeTagsModal> createState() => _ChangeTagsModalState();
}

class _ChangeTagsModalState extends State<ChangeTagsModal> {
  TextEditingController tagController = TextEditingController();
  List<String> tagsList = [];
  String error = "";

  void initState() {
    super.initState();
    getTags();
  }

  void getTags() async {
    try {
      DocumentSnapshot documentSnapshot =
          await firestore.collection('posts').doc(widget.idPost).get();
      setState(() {
        tagsList = List.from(documentSnapshot['tags']);
      });
    } catch (e) {
      setState(() {
        error = e.toString().split('] ')[1];
      });
    }
  }

  void deleteTag(int index) {
    setState(() {
      tagsList.removeAt(index);
    });
  }

  void addTag() {
    try {
      if (tagsList.contains(tagController.text)) {
        setState(() {
          error = "Tag already exists";
        });
        return;
      }
      if (tagsList.length >= 3) {
        setState(() {
          error = "You can only add 3 tags";
        });
        return;
      }
      if (tagController.text == "") {
        setState(() {
          error = "Tag can't be empty";
        });
        return;
      }

      setState(() {
        tagsList.add(tagController.text);
        error = "";
      });
    } catch (e) {
      setState(() {
        error = e.toString().split('] ')[1];
      });
    }
  }

  void postTags() async {
    try {
      await firestore
          .collection('posts')
          .doc(widget.idPost)
          .update({'tags': tagsList});
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        error = e.toString().split('] ')[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 300,
          height: 650,
          // Add your modal content here
          child: Column(
            children: [
              SizedBox(height: 30),
              if (error != '')
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 5),
                      Container(
                        width: 250,
                        child: Text(
                          "${error}",
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              TextField(
                controller: tagController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      addTag();
                    },
                  ),
                  labelText: 'tag',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ), // Accessing idPost from widget argument
              Container(
                width: 250,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tagsList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200, // Set the desired width here
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tagsList[index]),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                tagsList.removeAt(index);
                              });
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  postTags();
                },
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send),
                      SizedBox(width: 10),
                      Text('Change tags')
                    ]),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  fixedSize:
                      Size(170, 35), // Set the width and height of the button
                  backgroundColor: Color(
                      0xFF6A1B9A), // Set the background color of the button
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CommentModal extends StatefulWidget {
  final String postId;

  const CommentModal({super.key, required this.postId});

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  String username = "";
  String profilePicture =
      "https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=db72d8e7-aa9d-4b64-886c-549987962cb2";
  TextEditingController commentController = TextEditingController();

  void initState() {
    super.initState();
    getUser();
  }

  void getUser() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();
    setState(() {
      username = snapshot['username'];
      profilePicture = snapshot['profilePicture'];
    });
  }

  void postComment() async {
    try {
      DocumentReference documentReference =
          firestore.collection("comments").doc();
      // Set the data for the document.
      Map<String, dynamic> data = {
        'postId': widget.postId,
        'userId': auth.currentUser!.uid,
        'comment': commentController.text,
        'timestamp': DateTime.now(),
        'likes': [],
      };

      // Set the document.
      await documentReference.set(data);

      // Get the id of the document.
      String documentId = documentReference.id;

      DocumentSnapshot snapshot =
          await firestore.collection('posts').doc(widget.postId).get();
      List comments = snapshot['comments'];
      comments.add(documentId);
      await firestore
          .collection('posts')
          .doc(widget.postId)
          .update({'comments': comments});
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
            padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
            height: 500,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40.0),
                      child: Image.network(
                        profilePicture, // Replace with the actual path and filename of your image file
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  height: 200,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    maxLines: null,
                    controller: commentController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Write your comment ...',
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    postComment();
                  },
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 10),
                        Text('Post Comment')
                      ]),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    fixedSize:
                        Size(170, 35), // Set the width and height of the button
                    backgroundColor: Color(
                        0xFF6A1B9A), // Set the background color of the button
                  ),
                )
              ],
            )),
      ),
    );
  }
}

class UsersListModal extends StatefulWidget {
  const UsersListModal({super.key});

  @override
  State<UsersListModal> createState() => _UsersListModalState();
}

class _UsersListModalState extends State<UsersListModal> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  getUsers() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();
    List<String> listId = snapshot['followings'].cast<String>();
    listId.forEach((id) async {
      DocumentSnapshot userSnapshot =
          await firestore.collection('users').doc(id).get();
      setState(() {
        users.add({
          'id': userSnapshot.id,
          'username': userSnapshot['username'],
          'profilePicture': userSnapshot['profilePicture'],
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    users.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: 500,
        child: users.length == 0
            ? Center(child: Text('No users found'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            userId: users[index]['id'],
                            username: users[index]['username'],
                            profilePicture: users[index]['profilePicture'],
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(users[index]['profilePicture']),
                    ),
                    title: Text(users[index]['username']),
                  );
                },
              ),
      ),
    );
  }
}

class FollowersListModal extends StatefulWidget {
  const FollowersListModal({super.key});

  @override
  State<FollowersListModal> createState() => _FollowersListModalState();
}

class _FollowersListModalState extends State<FollowersListModal> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  getUsers() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();
    List<String> listId = snapshot['followers'].cast<String>();
    listId.forEach((id) async {
      DocumentSnapshot userSnapshot =
          await firestore.collection('users').doc(id).get();
      setState(() {
        users.add({
          'id': userSnapshot.id,
          'username': userSnapshot['username'],
          'profilePicture': userSnapshot['profilePicture'],
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    users.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
          padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
          height: 500,
          child: users.length == 0
              ? Center(child: Text('No users found'))
              : Column(
                  children: [
                    Text("Followers : ${users.length}"),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserProfilePage(
                                      userId: users[index]['id'])),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(users[index]['profilePicture']),
                          ),
                          title: Text(users[index]['username']),
                        );
                      },
                    ),
                  ],
                )),
    );
  }
}

class FollowingsListModal extends StatefulWidget {
  const FollowingsListModal({super.key});

  @override
  State<FollowingsListModal> createState() => _FollowingsListModallState();
}

class _FollowingsListModallState extends State<FollowingsListModal> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  getUsers() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();
    List<String> listId = snapshot['followings'].cast<String>();
    listId.forEach((id) async {
      DocumentSnapshot userSnapshot =
          await firestore.collection('users').doc(id).get();
      setState(() {
        users.add({
          'id': userSnapshot.id,
          'username': userSnapshot['username'],
          'profilePicture': userSnapshot['profilePicture'],
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    users.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
          padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
          height: 500,
          child: users.length == 0
              ? Center(child: Text('No users found'))
              : Column(
                  children: [
                    Text("Followings : ${users.length}"),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserProfilePage(
                                      userId: users[index]['id'])),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(users[index]['profilePicture']),
                          ),
                          title: Text(users[index]['username']),
                        );
                      },
                    ),
                  ],
                )),
    );
  }
}

void showErrorMessage(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Stack(
        children: [
          Container(
              padding: EdgeInsets.all(16),
              height: 90,
              decoration: BoxDecoration(
                  color: Color(0xFFC72C41),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 20),
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Oh snap!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            )),
                        Flexible(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ]),
                ],
              )),
          Positioned(
              top: -6,
              left: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    color: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ],
              ))
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

void showInfoMessage(String message, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Stack(
        children: [
          Container(
              padding: EdgeInsets.all(16),
              height: 90,
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 44, 199, 57),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 60),
                  Icon(Icons.verified, color: Colors.white),
                  SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Good!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            )),
                        Text(message,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ]),
                ],
              )),
          Positioned(
              top: -6,
              left: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    color: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ],
              ))
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
