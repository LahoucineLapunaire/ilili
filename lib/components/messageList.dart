import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/chat.dart';
import 'package:Ilili/components/floattingButton.dart';

import 'appRouter.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;
final FirebaseAuth auth = FirebaseAuth.instance;

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  List<dynamic> chatList = [];

  void initState() {
    super.initState();
    getConversation();
  }

  getConversation() async {
    try {
      DocumentSnapshot userDoc =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    List<String> chats = List<String>.from(userDoc['chats']);
    List<dynamic> result = [];
    String lastMessage = '';
    for (String chatId in chats) {
      QuerySnapshot<Map<String, dynamic>> chatSnapshot = await firestore
          .collection('chats')
          .doc(auth.currentUser!.uid)
          .collection(chatId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (chatSnapshot.docs.isNotEmpty) {
        lastMessage = chatSnapshot.docs.first['message'];
      } else {
        lastMessage = '';
      }
      result.add({
        'userId': chatId,
        'lastMessage': lastMessage,
      });
    }
    setState(() {
      chatList = result;
    });
    } catch (e) {
      print("Error getting conversations : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButtonUserMessage(),
      appBar: AppBar(
        backgroundColor: Color(0xFFFAFAFA),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppRouter(index: 0),
        ));
          },
        ),
        title: Text(
          "Message",
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: WillPopScope(onWillPop:(){
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppRouter(index: 0),
        ));
        return Future.value(false);
      }, child:Center(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            print(userSnapshot.connectionState);
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            List<String> chatIds = userSnapshot.data!['chats'] != null
                ? List<String>.from(userSnapshot.data!['chats'])
                : [];

            if (chatIds.isEmpty) {
              return Container(
                height: 200,
                child: Center(
                  child: Text(
                    "No message yet, to start a chat, please press the + button.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: chatIds.length,
              itemBuilder: (context, index) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: firestore
                      .collection('chats')
                      .doc(auth.currentUser!.uid)
                      .collection(chatIds[index])
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, chatSnapshot) {
                    String lastMessage = chatSnapshot.hasData
                        ? chatSnapshot.data!.docs.isNotEmpty
                            ? chatSnapshot.data!.docs.first['message']
                            : ''
                        : '';
                    return UserCardSection(
                      userId: chatIds[index],
                      lastMessage: lastMessage,
                      isRead: chatSnapshot.hasData
                          ? chatSnapshot.data!.docs.isNotEmpty
                              ? chatSnapshot.data!.docs.first['read']
                              : false
                          : false,
                    );
                  },
                );
              },
            );
          },
        ),
      ),)
    );
  }
}

class UserCardSection extends StatefulWidget {
  final String userId;
  final String lastMessage;
  final bool isRead;
  const UserCardSection(
      {super.key,
      required this.userId,
      required this.lastMessage,
      required this.isRead});

  @override
  State<UserCardSection> createState() => _UserCardSectionState();
}

class _UserCardSectionState extends State<UserCardSection> {
  String username = '';
  String profilePicture =
      'https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=db72d8e7-aa9d-4b64-886c-549987962cb2';
  String message = '';
  bool isPictureLoaded = false;

  void initState() {
    super.initState();
    getUserInfo();
  }

  getUserInfo() {
    firestore.collection('users').doc(widget.userId).get().then((value) {
      setState(() {
        username = value['username'];
        profilePicture = value['profilePicture'];
        isPictureLoaded = true;
        if (widget.lastMessage.length > 20) {
          message = widget.lastMessage.substring(0, 20) + '...';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatPage(
                    userId: widget.userId,
                    username: username,
                    profilePicture: profilePicture)));
      },
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20, 15, 15, 15),
        child: Row(
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
                    child: CircularProgressIndicator(
                      color: Colors.grey,
                    ),
                  ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    )),
                widget.isRead
                    ? Text(
                        widget.lastMessage.length > 20
                            ? widget.lastMessage.substring(0, 20) + '...'
                            : widget.lastMessage,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400))
                    : Text(
                        widget.lastMessage.length > 20
                            ? widget.lastMessage.substring(0, 20) + '...'
                            : widget.lastMessage,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
