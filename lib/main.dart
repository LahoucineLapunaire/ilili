import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Ilili/components/appRouter.dart';
import 'package:Ilili/components/emailNotVerified.dart';
import 'package:Ilili/components/getStarted.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDWjIzP1Fn3dHcbWCOs1WVf6lFBlcQIYgE",
        appId: "1:593268336010:web:5ceffd538c530070c71473",
        messagingSenderId: "593268336010",
        projectId: "ilili-7ebc6",
        storageBucket: "ilili-7ebc6.appspot.com/",
      ),
    );
  } else {
    await Firebase.initializeApp();
    await checkPermission();
    initNotification();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  initSharedPreferences();
  GetKeysFromRemoteConfig();
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
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
    if (FirebaseAuth.instance.currentUser != null) {
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
  var storageStatus = await Permission.storage.request();
  if (storageStatus != PermissionStatus.granted) {
    print('Storage Permission not granted');
    checkPermission();
    return false;
  } else {
    print('Notification Permission granted');
  }
  var notificationStatus = await Permission.notification.request();
  if (notificationStatus != PermissionStatus.granted) {
    print('Notification Permission not granted');
    checkPermission();
    return false;
  } else {
    print('Storage Permission granted');
  }
  var microphoneStatus = await Permission.microphone.request();
  if (microphoneStatus != PermissionStatus.granted) {
    print('Microphone Permission not granted');
    checkPermission();
    return false;
  } else {
    print('Microphone Permission granted');
  }
  return true;
}

void initSharedPreferences() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  if (prefs.getBool("notification") == null) {
    prefs.setBool("notification", true);

    if (FirebaseAuth.instance.currentUser != null) {
      messaging.subscribeToTopic(FirebaseAuth.instance.currentUser!.uid);
    }
  }
  if (prefs.getString("language") == null) {
    prefs.setString("language", "English");
  }
}

void initNotification() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  messaging.subscribeToTopic("general");
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
  print("notification init");
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("You received a message");
    print("onMessage: ${message.notification?.body}");
    print("onMessage: ${message.data}");
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("You received a Background message");
  print("onMessage: ${message.notification?.body}");
  print("onMessage: ${message.data}");
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
        title: 'Ilili',
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
      title: 'Ilili',
      home: AppRouter(
        index: 0,
      ),
    );
  }
}
