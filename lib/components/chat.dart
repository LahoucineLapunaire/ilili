import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ilili/components/changeProfile.dart';
import 'package:intl/intl.dart';

FirebaseAuth auth = FirebaseAuth.instance;

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference chatRef = firestore.collection('chats');

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
  late List<DocumentSnapshot> _docs;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: chatRef
          .doc(auth.currentUser?.uid)
          .collection(widget.otherUserID)
          .orderBy('timestamp')
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Text('Chargement'));
        }
        _docs = snapshot.data!.docs;
        print(_docs);
        if (_docs.isEmpty) {
          return const Center(child: Text('Envoyez votre premier message'));
        }
        return Column(
          children: _docs.map((document) {
            return document['userId'] == auth.currentUser?.uid
                ? CurrentUserMessage(document['message'], document['timestamp'])
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
      }).then((value) {
        chatRef.doc(otherUserID).collection(auth.currentUser?.uid ?? "").add({
          'message': textField.text,
          'userId': auth.currentUser?.uid,
          'timestamp': formattedDate,
        }).then((value) {
          textField.clear();
        });
      });
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
                    hintText: 'Entrez votre  message',
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
  const CurrentUserMessage(this.textMessage, this.dateMessage, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            dateMessage.toString().substring(13, 18),
            style: TextStyle(
              color: Colors.grey[400],
            ),
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
