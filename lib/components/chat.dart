import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ilili/components/changeProfile.dart';
import 'package:intl/intl.dart';

FirebaseAuth auth = FirebaseAuth.instance;

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference chatRef = firestore.collection('chats');
List<DocumentSnapshot> messageList = [];

class ChatPage extends StatefulWidget {
  final String userId;
  final String username;
  final String profilePicture;

  const ChatPage(
      {super.key,
      required this.userId,
      required this.username,
      required this.profilePicture});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF6A1B9A),
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.profilePicture),
              ),
              SizedBox(width: 20),
              Text(
                widget.username,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        bottomNavigationBar: MessageField(widget.userId),
        body: SingleChildScrollView(
            child: Center(
          child: Column(
            children: [ListSection(widget.userId)],
          ),
        )));
  }
}

class ListSection extends StatefulWidget {
  final String otherUserID;
  const ListSection(this.otherUserID, {Key? key}) : super(key: key);
  @override
  _ListSectionState createState() => _ListSectionState();
}

class _ListSectionState extends State<ListSection> {
  void initState() {
    super.initState();
  }

  void markAllAsRead() async {
    try {
      QuerySnapshot querySnapshot = await chatRef
          .doc(auth.currentUser!.uid)
          .collection(widget.otherUserID)
          .get();
      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        await chatRef
            .doc(auth.currentUser!.uid)
            .collection(widget.otherUserID)
            .doc(document.id)
            .update({'read': true});
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: chatRef
          .doc(widget.otherUserID)
          .collection(auth.currentUser!.uid)
          .orderBy('timestamp')
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        markAllAsRead();
        if (!snapshot.hasData) {
          return const Center(child: Text('Loading...'));
        }
        messageList = snapshot.data!.docs;
        if (messageList.isEmpty) {
          return Container(
            height: 200,
            child: Center(
              child: Text(
                "No message yet, please send a message to start a chat.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }
        return Column(
          children: messageList.map((document) {
            if (!document["read"]) {
              print("document : ${document} is ${document["read"]}");
            }
            return document['userId'] == auth.currentUser?.uid
                ? CurrentUserMessage(document['message'], document['timestamp'],
                    document["read"])
                : OtherUserMessage(document['message'], document['timestamp']);
          }).toList(),
        );
      },
    );
  }
}

class MessageField extends StatelessWidget {
  final String otherUserID;
  final textField = TextEditingController();
  MessageField(this.otherUserID, {Key? key}) : super(key: key);

  Future<void> sendMessage() async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm:ss').format(now);
    try {
      chatRef.doc(auth.currentUser?.uid).collection(otherUserID).add({
        'message': textField.text,
        'userId': auth.currentUser?.uid,
        'timestamp': formattedDate,
        'read': true,
      }).then((value) {
        chatRef.doc(otherUserID).collection(auth.currentUser?.uid ?? "").add({
          'message': textField.text,
          'userId': auth.currentUser?.uid,
          'timestamp': formattedDate,
          'read': false,
        }).then((value) {
          addConversation();
          textField.clear();
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

  void sendNotification() {
    try {
      FirebaseMessaging.instance
          .sendMessage(
              to: '/topics/chat',
              data: {
                "title": "New message",
                "body": "A newmessage from a user",
              },
              ttl: 10,
              messageId: "azerty123",
              messageType: "follow",
              collapseKey: "aqwzsx")
          .catchError((e) {
        print("error sending notification : ${e.toString()}");
      });
      print("notification sent");
    } catch (e) {
      print("error sending notification : ${e.toString()}");
    }
  }

  addConversation() async {
    try {
      DocumentSnapshot documentSnapshot =
          await firestore.collection("users").doc(auth.currentUser?.uid).get();
      List<dynamic> chats = documentSnapshot.get("chats");
      if (!chats.contains(otherUserID)) {
        chats.add(otherUserID);
        firestore.collection("users").doc(auth.currentUser?.uid).update({
          "chats": chats,
        });
      }
      documentSnapshot =
          await firestore.collection("users").doc(otherUserID).get();
      chats = documentSnapshot.get("chats");
      if (!chats.contains(auth.currentUser?.uid)) {
        chats.add(auth.currentUser?.uid);
        firestore.collection("users").doc(otherUserID).update({
          "chats": chats,
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
      child: BottomAppBar(
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textField,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Write your message...',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => sendMessage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurrentUserMessage extends StatelessWidget {
  final String textMessage;
  final String dateMessage;
  final bool isRead;
  const CurrentUserMessage(this.textMessage, this.dateMessage, this.isRead,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                dateMessage.toString().substring(13, 18),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(width: 10),
              isRead
                  ? const Icon(
                      Icons.done_all,
                      color: Colors.blue,
                      size: 20,
                    )
                  : const Icon(
                      Icons.done,
                      color: Colors.grey,
                      size: 20,
                    ),
            ],
          ),
          SizedBox(width: 10), // Add some spacing
          Flexible(
            // Use Flexible to adapt to text height
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.blue,
              ),
              child: Text(
                textMessage,
                style: const TextStyle(color: Colors.white, fontSize: 17),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class OtherUserMessage extends StatelessWidget {
  final String textMessage;
  final String dateMessage;
  const OtherUserMessage(this.textMessage, this.dateMessage, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            // Use Flexible to adapt to text height
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade300,
              ),
              child: Text(
                textMessage,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
          SizedBox(width: 10), // Add some spacing
          Text(
            dateMessage.toString().substring(13, 18),
            style: TextStyle(
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
