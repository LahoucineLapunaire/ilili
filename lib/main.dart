import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/appRouter.dart';
import 'package:ilili/components/emailNotVerified.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/signup.dart';

FirebaseAuth auth = FirebaseAuth.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initNotification();
  await checkPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  initSharedPreferences();
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

Future<bool> checkPermission() async {
  var status = await Permission.storage.request();
  if (status != PermissionStatus.granted) {
    print('Permission not granted');
  }
  if (await Permission.microphone.request().isGranted) {
    print('Permission granted');
    return true;
  } else {
    print('Permission denied');
    return false;
  }
}

void initSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getBool("followerNotificaiton") == null) {
    prefs.setBool("followerNotificaiton", true);
  }
  if (prefs.getBool("chatNotificaiton") == null) {
    prefs.setBool("chatNotificaiton", true);
  }
  if (prefs.getBool("commentNotificaiton") == null) {
    prefs.setBool("commentNotificaiton", true);
  }
  if (prefs.getString("language") == null) {
    prefs.setString("language", "English");
  }
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
  SharedPreferences prefs = await SharedPreferences.getInstance();
  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    bool followerNotificaiton = prefs.getBool("followerNotificaiton")!;
    bool chatNotificaiton = prefs.getBool("chatNotificaiton")!;
    bool commentNotificaiton = prefs.getBool("commentNotificaiton")!;
    if (message.data["receiver"] == auth.currentUser!.uid &&
        ((message.data["type"] == "follow" && followerNotificaiton) ||
            (message.data["type"] == "chat" && chatNotificaiton) ||
            (message.data["type"] == "comment" && commentNotificaiton))) {
      print("You received a message");
      print("onMessage: ${message.notification?.body}");
      print("onMessage: ${message.data}");
    }
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool followerNotificaiton = prefs.getBool("followerNotificaiton")!;
  bool chatNotificaiton = prefs.getBool("chatNotificaiton")!;
  bool commentNotificaiton = prefs.getBool("commentNotificaiton")!;
  if (message.data["receiver"] == auth.currentUser!.uid &&
      ((message.data["type"] == "follow" && followerNotificaiton) ||
          (message.data["type"] == "chat" && chatNotificaiton) ||
          (message.data["type"] == "comment" && commentNotificaiton))) {
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
