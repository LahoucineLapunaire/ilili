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
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
Reference storageRef = FirebaseStorage.instance.ref("comments");
FirebaseAuth auth = FirebaseAuth.instance;
final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

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
  String title = "";
  bool isTapped = false;
  bool isPictureLoaded = false;

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
      isPictureLoaded = true;
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
      title = ds.data()!['title'];
    });
  }

  Future<void> loadAudio() async {
    try {
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
      setState(() {
        isTapped = true;
        isPlaying = true;
      });
      if (audioPath != null) {
        await audioPlayer.play(UrlSource(audioPath)).then((value) {});
      }
    } catch (e) {
      showErrorMessage(e.toString(), context);
    }
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

  void showDeleteAlert(BuildContext context) {
    // Create a AlertDialog
    AlertDialog alertDialog = AlertDialog(
      title: Text("Do you want to delete this post?"),
      actions: [
        // OK button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
          ),
          child: Text('No', style: TextStyle(color: Colors.black)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6A1B9A),
          ),
          child: Text('Yes', style: TextStyle(color: Colors.white)),
          onPressed: () {
            deletePost();
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    // Show the alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alertDialog;
      },
    );
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
                  redirectToUser();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    isPictureLoaded
                        ? SizedBox(
                            height: 50,
                            width: 50,
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(profilePicture),
                            ),
                          )
                        : Center(
                            child:
                                CircularProgressIndicator(color: Colors.grey),
                          ),
                    SizedBox(width: 10),
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  // Handle menu item selection
                  if (value == "Modify Post") {
                    openModal(context);
                  } else if (value == "Delete Post") {
                    showDeleteAlert(context);
                  } else if (value == "Report Post") {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return ReportModal(
                          isPost: true,
                          reportId: widget.postId,
                          username: username,
                          userId: widget.userId,
                          title: title,
                          content: audioPath,
                        );
                      },
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  if (widget.isOwner)
                    PopupMenuItem(
                      value: 'Modify Post',
                      child: Text('Modify Post'),
                      textStyle: TextStyle(color: Colors.black),
                    ),
                  if (widget.isOwner)
                    PopupMenuItem(
                      value: 'Delete Post',
                      child: Text('Delete Post'),
                      textStyle: TextStyle(color: Colors.red),
                    ),
                  PopupMenuItem(
                    value: 'Report Post',
                    child: Text('Report Post'),
                    textStyle: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          // ---------------------
          isTapped
              ? Container(
                  child: Row(
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
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF6A1B9A), // Background color
                    shape:
                        BoxShape.circle, // You can change the shape if needed
                  ),
                  child: IconButton(
                    onPressed: () {
                      loadAudio();
                    },
                    icon: Icon(
                      Icons.play_arrow,
                      color: Colors.white, // Icon color
                    ),
                  ),
                ),
          // ---------------------
          SizedBox(height: 10),
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
  String ownerId = "";
  String profilePicture =
      "https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=db72d8e7-aa9d-4b64-886c-549987962cb2";
  TextEditingController commentController = TextEditingController();

  void initState() {
    super.initState();
    getUser();
    getPostOwner();
  }

  void getPostOwner() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await firestore.collection('posts').doc(widget.postId).get();
    setState(() {
      ownerId = snapshot['userId'];
    });
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
      int score = snapshot['score'];
      score += 5;
      comments.add(documentId);
      await firestore
          .collection('posts')
          .doc(widget.postId)
          .update({'comments': comments, 'score': score});

      showInfoMessage("Comment is posted !", context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
      sendNotificationToTopic(
          "comment", "New comment !", "$username commented on your post !", {
        "sender": auth.currentUser!.uid,
        "receiver": ownerId,
        "type": "comment",
        "click_action": "FLUTTER_COMMENT_CLICK",
      });
      Navigator.pop(context);
    } catch (e) {
      print("Error posting comment : ${e.toString()}");
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
        padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
        height: 500,
        child: users.length == 0
            ? Center(child: Text('No users found'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Text("Followings : ${users.length}"),
                      ListTile(
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
                      )
                    ],
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

class ReportModal extends StatefulWidget {
  final bool isPost;
  final String reportId;
  final String username;
  final String userId;
  final String title;
  final String content;
  const ReportModal(
      {super.key,
      required this.isPost,
      required this.username,
      required this.userId,
      required this.content,
      required this.reportId,
      required this.title});

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  TextEditingController reportController = TextEditingController();

  reportComment() async {
    try {
      final smtpServer =
          gmail('moderation.ilili@gmail.com', 'gpubnhzldelidwcq');

      // Create a message
      final message = Message()
        ..from = Address('moderation.ilili@gmail.com', 'Moderation')
        ..recipients.add('moderation.ilili@gmail.com')
        ..subject = 'Report of the comment ${widget.reportId}'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
<style>
  body {
    font-family: Arial, sans-serif;
    background-color: #f5f5f5;
    margin: 0;
    padding: 20px;
  }
  h2 {
    color: #333;
    margin-bottom: 10px;
  }
  h3 {
    color: #666;
    margin-bottom: 5px;
  }
  p {
    color: #555;
    margin-bottom: 5px;
  }
</style>
</head>
<body>
  <h2>The user ${auth.currentUser!.uid}, email address ${auth.currentUser?.email}, reported the following comment:</h2>
  <div style="background-color: #fff; border: 1px solid #ddd; padding: 10px;">
    <h3>User: ${widget.username} (User ID: ${widget.userId})</h3>
    <p>Comment ID: ${widget.reportId}</p>
    <p>Comment content:</p>
    <div style="background-color: #f9f9f9; border: 1px solid #ddd; padding: 10px; margin: 10px 0;">
      ${widget.content}
    </div>
  </div>
  <div style="background-color: #fff; border: 1px solid #ddd; padding: 10px; margin-top: 10px;">
    <h3>The reason for this report is:</h3>
    <p>${reportController.text}</p>
    <p>Reported at: ${DateTime.now().toString()}</p>
  </div>
</body>
</html>
''';
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
      Navigator.pop(context);
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  reportPost() async {
    try {
      final smtpServer =
          gmail('moderation.ilili@gmail.com', 'gpubnhzldelidwcq');

      // Create a message
      final message = Message()
        ..from = Address('moderation.ilili@gmail.com', 'Moderation')
        ..recipients.add('moderation.ilili@gmail.com')
        ..subject = 'Report of the comment ${widget.reportId}'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
<style>
  body {
    font-family: Arial, sans-serif;
    background-color: #f5f5f5;
    margin: 0;
    padding: 20px;
  }
  h2 {
    color: #333;
    margin-bottom: 10px;
  }
  h3 {
    color: #666;
    margin-bottom: 5px;
  }
  p {
    color: #555;
    margin-bottom: 5px;
  }
</style>
</head>
<body>
  <h2>The user ${auth.currentUser!.uid}, email address ${auth.currentUser?.email}, reported the following post:</h2>
  <div style="background-color: #fff; border: 1px solid #ddd; padding: 10px;">
    <h3>User: ${widget.username} (User ID: ${widget.userId})</h3>
    <p>Post ID: ${widget.reportId}</p>
    <p>Post title: ${widget.title}</p>
    <p>Post content:</p>
    <div style="background-color: #f9f9f9; border: 1px solid #ddd; padding: 10px; margin: 10px 0;">
      ${widget.content}
    </div>
  </div>
  <div style="background-color: #fff; border: 1px solid #ddd; padding: 10px; margin-top: 10px;">
    <h3>The reason for this report is:</h3>
    <p>${reportController.text}</p>
    <p>Reported at: ${DateTime.now().toString()}</p>
  </div>
</body>
</html>
''';
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
      Navigator.pop(context);
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
        height: 500,
        child: Column(
          children: [
            Text(
              "Report of ${widget.isPost ? 'post' : 'comment'}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Why do you want to report this ${widget.isPost ? 'post' : 'comment'}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                maxLines: null,
                controller: reportController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write the report reason ...',
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                widget.isPost ? reportPost() : reportComment();
              },
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.report),
                SizedBox(width: 10),
                widget.isPost ? Text('Report post') : Text('Report comment')
              ]),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fixedSize:
                    Size(180, 35), // Set the width and height of the button
                backgroundColor:
                    Color(0xFF6A1B9A), // Set the background color of the button
              ),
            )
          ],
        ),
      ),
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

void showInfoMessage(
    String message, BuildContext context, VoidCallback hideCallback) {
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
                      hideCallback;
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
