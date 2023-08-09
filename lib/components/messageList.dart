import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ilili/components/chat.dart';
import 'package:ilili/components/floattingButton.dart';

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
    print(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButtonUserMessage(),
      appBar: AppBar(
        backgroundColor: Color(0xFF6A1B9A),
        title: Text("Messages"),
      ),
      body: Center(
        child: Column(children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatList.length,
              itemBuilder: (context, index) {
                return UserCardSection(
                  userId: chatList[index]['userId'],
                  lastMessage: chatList[index]['lastMessage'],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class UserCardSection extends StatefulWidget {
  final String userId;
  final String lastMessage;

  const UserCardSection(
      {super.key, required this.userId, required this.lastMessage});

  @override
  State<UserCardSection> createState() => _UserCardSectionState();
}

class _UserCardSectionState extends State<UserCardSection> {
  String username = '';
  String profilePicture =
      'https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=db72d8e7-aa9d-4b64-886c-549987962cb2';
  String message = '';

  void initState() {
    super.initState();
    getUserInfo();
    if (widget.lastMessage.length > 20) {
      setState(() {
        message = widget.lastMessage.substring(0, 20) + '...';
      });
    } else {
      setState(() {
        message = widget.lastMessage;
      });
    }
  }

  getUserInfo() {
    if (widget.lastMessage.length > 20) {
      message = widget.lastMessage.substring(0, 20) + '...';
    }
    firestore.collection('users').doc(widget.userId).get().then((value) {
      setState(() {
        username = value['username'];
        profilePicture = value['profilePicture'];
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
        padding: const EdgeInsets.fromLTRB(15, 10, 10, 10),
        child: Row(
          children: [
            SizedBox(
              height: 50,
              width: 50,
              child: CircleAvatar(
                backgroundImage: NetworkImage(profilePicture),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(message,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
