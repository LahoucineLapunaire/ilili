import 'dart:js';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/UserProfilePage.dart';
import 'package:ilili/components/appRouter.dart';
import 'package:ilili/components/chat.dart';
import 'package:ilili/components/emailNotVerified.dart';
import 'package:ilili/components/postPage.dart';
import 'components/signup.dart';

FirebaseAuth auth = FirebaseAuth.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initNotification();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  auth.authStateChanges().listen((User? user) {
    if (user == null) {
      runApp(const UnLogged());
    } else if (user.emailVerified == false) {
      runApp(const EmailNotVerified());
    } else {
      runApp(const Logged());
    }
  });
}

void initNotification() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.subscribeToTopic('comment');
  await messaging.subscribeToTopic('follow');
  await messaging.subscribeToTopic('chat');
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data["receiver"] == auth.currentUser!.uid) {
      print("You received a message");
      print("onMessage: ${message.notification?.body}");
      print("onMessage: ${message.data}");
    }
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data["receiver"] == auth.currentUser!.uid) {
    print("Handling a background message: ${message.messageId}");
    print("onMessage: ${message.notification?.body}");
  }
}

class UnLogged extends StatelessWidget {
  const UnLogged({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Color(0xFF6A1B9A), // Change this to your desired color
        ),
        title: 'ilili',
        home: Scaffold(
          body: SignupPage(),
        ));
  }
}

class Logged extends StatelessWidget {
  const Logged({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF6A1B9A), // Change this to your desired color
      ),
      title: 'ilili',
      home: AppRouter(),
    );
  }
}
