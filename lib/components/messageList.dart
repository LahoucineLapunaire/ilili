import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ilili/components/floattingButton.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;
final FirebaseAuth auth = FirebaseAuth.instance;

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  List<dynamic> conversations = [];

  void initState() {
    super.initState();
    getConversation();
  }

  getConversation() async {
    try {
      try {
        DocumentSnapshot docSnapshot = await firestore
            .collection("chats")
            .doc(auth.currentUser?.uid)
            .get();

        if (docSnapshot.exists) {
          Map<String, dynamic> data =
              docSnapshot.data() as Map<String, dynamic>;
          List<String> fieldNames = data.keys.toList();

          print("Field names in the document:");
          fieldNames.forEach((fieldName) {
            print(fieldName);
          });
        } else {
          print("Document not found");
        }
      } catch (e) {
        print(e.toString());
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
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
        child: Text("Messages"),
      ),
    );
  }
}
