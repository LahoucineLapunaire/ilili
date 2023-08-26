import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Ilili/components/appRouter.dart';
import 'package:Ilili/components/emailNotVerified.dart';
import 'package:Ilili/components/getStarted.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

FirebaseAuth auth = FirebaseAuth.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await checkPermission();
  initSharedPreferences();
  GetKeysFromRemoteConfig();
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

Future<void> GetKeysFromRemoteConfig() async {
  try {
    if (auth.currentUser != null) {
      // Initialize Firebase Remote Config.
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();

      final secretKeyId = remoteConfig.getString('private_key_id');
      final secretKey = remoteConfig.getString('private_key');
      final smtpKey = remoteConfig.getString('smtp_key');

      // Create a SharedPreferences instance.
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Save the keys to SharedPreferences.
      prefs.setString("private_key_id", secretKeyId);
      prefs.setString("private_key", secretKey);
      prefs.setString("smtp_key", smtpKey);
      print("keys saved to shared preferences");
    }
  } catch (e) {
    print("error getting keys: ${e.toString()}");
  }
}

Future<bool> checkPermission() async {
  var status = await Permission.storage.request();
  Permission.notification.request();
  if (status != PermissionStatus.granted) {
    print('Permission not granted');
    checkPermission();
    return false;
  }
  if (await Permission.microphone.request().isGranted) {
    print('Permission granted');
    return true;
  } else {
    print('Permission denied');
    checkPermission();
    return false;
  }
}

void initSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getBool("followerNotification") == null) {
    prefs.setBool("followerNotificaiton", true);
  }
  if (prefs.getBool("chatNotification") == null) {
    prefs.setBool("chatNotificaiton", true);
  }
  if (prefs.getBool("commentNotification") == null) {
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
    bool followerNotificaiton = prefs.getBool("followerNotification") ??
        true && (message.data["type"] == "follow");
    bool chatNotificaiton = prefs.getBool("chatNotification") ??
        true && (message.data["type"] == "chat");
    bool commentNotificaiton = prefs.getBool("commentNotification") ??
        true && (message.data["type"] == "comment");
    print("followerNotificaiton : $followerNotificaiton");
    print("chatNotificaiton : $chatNotificaiton");
    print("commentNotificaiton : $commentNotificaiton");
    try {
      if (message.data["receiver"] == auth.currentUser!.uid &&
          (followerNotificaiton || chatNotificaiton || commentNotificaiton)) {
        print("You received a message");
        print("onMessage: ${message.notification?.body}");
        print("onMessage: ${message.data}");
      } else {
        print("You received a message but you are not allowed to receive it");
        return;
      }
    } catch (e) {
      print("error in onMessage: ${e.toString()}");
    }
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  return;
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
          body: GetStartedPage(),
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
      home: AppRouter(
        index: 0,
      ),
    );
  }
}
