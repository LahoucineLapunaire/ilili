import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'notification.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference chatRef = firestore.collection('chats');
List<DocumentSnapshot> messageList = [];
String myUsername = "";
String myProfilePicture = "";

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
  final ScrollController scrollController = ScrollController();

  void initState() {
    super.initState();
    getMyInfo();
    // Use addPostFrameCallback to perform actions after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        scrollToBottom();
      });
    });
  }

// Scroll to the bottom of a scrollable view using a scroll controller.
  void scrollToBottom() {
    try {
      // Use the scroll controller to jump to the maximum scroll extent.
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    } catch (e) {
      // Handle any exceptions that may occur while scrolling.
      print(e.toString());
    }
  }

// Fetch user information from Firestore for the currently authenticated user.
  void getMyInfo() async {
    try {
      // Retrieve the user's document from the "users" collection using their UID.
      DocumentSnapshot documentSnapshot =
          await firestore.collection("users").doc(auth.currentUser?.uid).get();

      // Update the state with the user's profile picture and username.
      setState(() {
        myProfilePicture = documentSnapshot.get("profilePicture");
        myUsername = documentSnapshot.get("username");
      });
    } catch (e) {
      // Handle any exceptions that may occur while fetching user information.
      print(e.toString());
    }
  }

  void dispose() {
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
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.profilePicture),
              ),
              SizedBox(width: 10),
              Text(
                widget.username,
                style: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: MessageField(widget.userId, widget.username),
        body: SingleChildScrollView(
            controller: scrollController,
            child: Center(
              child: Column(
                children: [
                  ListSection(widget.userId),
                ],
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
      // Fetch a QuerySnapshot containing all documents in the chat collection
      QuerySnapshot querySnapshot = await chatRef
          .doc(auth.currentUser!.uid)
          .collection(widget.otherUserID)
          .get();

      // Loop through each document in the QuerySnapshot
      for (QueryDocumentSnapshot document in querySnapshot.docs) {
        // Update the 'read' field of the current document to 'true'
        await chatRef
            .doc(auth.currentUser!.uid)
            .collection(widget.otherUserID)
            .doc(document.id)
            .update({'read': true});
      }
    } catch (e) {
      // Handle any exceptions that may occur during the process
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
        return Container(
          margin: EdgeInsets.only(bottom: 50),
          child: Column(
            children: messageList.map((document) {
              return document['userId'] == auth.currentUser?.uid
                  ? CurrentUserMessage(document['message'],
                      document['timestamp'], document["read"])
                  : OtherUserMessage(
                      document['message'], document['timestamp']);
            }).toList(),
          ),
        );
      },
    );
  }
}

class MessageField extends StatefulWidget {
  final String otherUserID;
  final String username;

  MessageField(this.otherUserID, this.username, {Key? key}) : super(key: key);

  @override
  _MessageFieldState createState() => _MessageFieldState();
}

class _MessageFieldState extends State<MessageField> {
  final textField = TextEditingController();
  EdgeInsets margin = EdgeInsets.zero;

  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    textField.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    // Check if the text input is empty
    if (textField.text.isEmpty) {
      return;
    }

    // Get the current date and time
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm:ss').format(now);

    try {
      // Add the message to the sender's chat collection
      chatRef.doc(auth.currentUser?.uid).collection(widget.otherUserID).add({
        'message': textField.text,
        'userId': auth.currentUser?.uid,
        'timestamp': formattedDate,
        'read': true,
      }).then((value) {
        // Add the message to the receiver's chat collection
        chatRef
            .doc(widget.otherUserID)
            .collection(auth.currentUser?.uid ?? "")
            .add({
          'message': textField.text,
          'userId': auth.currentUser?.uid,
          'timestamp': formattedDate,
          'read': false,
        }).then((value) {
          // Add the conversation to the user's chats list
          addConversation();
          // Clear the text input field
          textField.clear();
        });
      });

      // Send a notification to the receiver
      sendNotificationToTopic("${widget.otherUserID}", "$myUsername",
          "${textField.text}", myProfilePicture, {
        "sender": auth.currentUser!.uid,
        "receiver": widget.otherUserID,
        "type": "chat",
        "click_action": "FLUTTER_CHAT_CLICK",
      });
    } catch (e) {
      print(e.toString());
    }
  }

  void addConversation() async {
    try {
      // Get the user's chats list and update it
      DocumentSnapshot documentSnapshot =
          await firestore.collection("users").doc(auth.currentUser?.uid).get();
      List<dynamic> chats = documentSnapshot.get("chats");
      if (!chats.contains(widget.otherUserID)) {
        chats.add(widget.otherUserID);
        firestore.collection("users").doc(auth.currentUser?.uid).update({
          "chats": chats,
        });
      }

      // Get the receiver's chats list and update it
      documentSnapshot =
          await firestore.collection("users").doc(widget.otherUserID).get();
      chats = documentSnapshot.get("chats");
      if (!chats.contains(auth.currentUser?.uid)) {
        chats.add(auth.currentUser?.uid);
        firestore.collection("users").doc(widget.otherUserID).update({
          "chats": chats,
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void changeMargin(bool isFocused) {
    if (isFocused) {
      // If the text input is focused, change the margin to make space for the keyboard
      print("focused");
      setState(() {
        margin = EdgeInsets.only(bottom: 50);
      });
    } else {
      // If the text input is not focused, reset the margin
      print("not focused");
      setState(() {
        margin = EdgeInsets.only(bottom: 0);
      });
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
                style: TextStyle(
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  color: Colors.grey,
                  fontSize: 12,
                ),
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
              fontFamily: GoogleFonts.poppins().fontFamily,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
