import 'package:Ilili/components/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/chat.dart';

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

  @override
  void initState() {
    super.initState();
    getConversation();
  }

  getConversation() async {
    try {
      // Fetch the user's document from Firestore using their UID
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(auth.currentUser!.uid).get();

      // Extract the list of chat IDs from the user's document
      List<String> chats = List<String>.from(userDoc['chats']);
      List<dynamic> result = [];
      String lastMessage = '';

      // Iterate through each chat ID in the user's chats
      for (String chatId in chats) {
        // Query the Firestore for the last message in the chat, ordered by timestamp
        QuerySnapshot<Map<String, dynamic>> chatSnapshot = await firestore
            .collection('chats')
            .doc(auth.currentUser!.uid)
            .collection(chatId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        // Check if there are any messages in the chat
        if (chatSnapshot.docs.isNotEmpty) {
          // Get the last message from the first document in the query result
          lastMessage = chatSnapshot.docs.first['message'];
        } else {
          lastMessage = ''; // No messages in this chat
        }

        // Add chat information (user ID and last message) to the result list
        result.add({
          'userId': chatId,
          'lastMessage': lastMessage,
        });
      }

      // Update the chatList state variable with the result
      setState(() {
        chatList = result;
      });
    } catch (e) {
      // Handle any errors that may occur during the execution
      print("Error getting conversations : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: const FloatingActionButtonUserMessage(),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFAFA),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AppRouter(index: 0),
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
        body: WillPopScope(
          onWillPop: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppRouter(index: 0),
                ));
            return Future.value(false);
          },
          child: Center(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: firestore
                  .collection('users')
                  .doc(auth.currentUser!.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                print(userSnapshot.connectionState);
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                List<String> chatIds = userSnapshot.data!['chats'] != null
                    ? List<String>.from(userSnapshot.data!['chats'])
                    : [];

                if (chatIds.isEmpty) {
                  return Container(
                    height: 200,
                    child: const Center(
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
          ),
        ));
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

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  // Function to fetch user information from Firestore based on userId
  void getUserInfo() {
    // Access the 'users' collection and retrieve a document with the provided userId
    firestore.collection('users').doc(widget.userId).get().then((value) {
      // Check if the widget is still mounted (to avoid state changes on an unmounted widget)
      if (mounted) {
        // Update the widget's state with the fetched user information
        setState(() {
          // Set the 'username' variable to the 'username' field in Firestore
          username = value['username'];

          // Set the 'profilePicture' variable to the 'profilePicture' field in Firestore
          profilePicture = value['profilePicture'];

          // Set 'isPictureLoaded' to true to indicate that the profile picture has been loaded
          isPictureLoaded = true;

          // Check if the 'lastMessage' is longer than 20 characters
          if (widget.lastMessage.length > 20) {
            // If so, truncate the 'lastMessage' and append '...' to indicate it's shortened
            message = '${widget.lastMessage.substring(0, 20)}...';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
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
        padding: const EdgeInsets.fromLTRB(20, 15, 15, 15),
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
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.grey,
                    ),
                  ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    )),
                widget.isRead
                    ? Text(
                        widget.lastMessage.length > 20
                            ? '${widget.lastMessage.substring(0, 20)}...'
                            : widget.lastMessage,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400))
                    : Text(
                        widget.lastMessage.length > 20
                            ? '${widget.lastMessage.substring(0, 20)}...'
                            : widget.lastMessage,
                        style: const TextStyle(
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

class FloatingActionButtonUserMessage extends StatefulWidget {
  const FloatingActionButtonUserMessage({super.key});

  @override
  State<FloatingActionButtonUserMessage> createState() =>
      _FloatingActionButtonUserMessageState();
}

class _FloatingActionButtonUserMessageState
    extends State<FloatingActionButtonUserMessage> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF6A1B9A),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return const UsersListModal();
          },
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
