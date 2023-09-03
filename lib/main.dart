import 'package:Ilili/components/OwnerProfile.dart';
import 'package:Ilili/components/PrivacyPolicy.dart';
import 'package:Ilili/components/addPost.dart';
import 'package:Ilili/components/home.dart';
import 'package:Ilili/components/settings.dart';
import 'package:Ilili/components/termsOfService.dart';
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
  // Ensure Flutter is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Initialize Firebase for web.
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDWjIzP1Fn3dHcbWCOs1WVf6lFBlcQIYgE",
        appId: "1:593268336010:web:5ceffd538c530070c71473",
        messagingSenderId: "593268336010",
        projectId: "ilili-7ebc6",
        storageBucket: "ilili-7ebc6.appspot.com/",
      ),
    );

    // Define routes for web.
    final Map<String, WidgetBuilder> routes = {
      '/privacypolicy': (context) => PrivacyPolicyPage(),
      '/termsofservice': (context) => TermsOfServicePage(),
      '/profilepage': (context) => OwnerProfilePage(),
      '/addpost': (context) => AddPostPage(),
    };
  } else {
    // Initialize Firebase for mobile.
    await Firebase.initializeApp();

    // Perform additional setup for mobile.
    await checkPermission();
    initNotification();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Initialize SharedPreferences.
  initSharedPreferences();

  // Fetch keys from Remote Config.
  GetKeysFromRemoteConfig();

  // Listen for changes in user authentication state.
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      // User is not logged in, show UnLogged page.
      runApp(const UnLogged());
    } else if (user.emailVerified == false) {
      // User's email is not verified, show EmailNotVerified page.
      runApp(const EmailNotVerified());
    } else {
      // User is logged in, show Logged page.
      runApp(const Logged());
    }
  });
}

Future<void> GetKeysFromRemoteConfig() async {
  try {
    // Check if a user is currently authenticated.
    if (FirebaseAuth.instance.currentUser != null) {
      // Initialize Firebase Remote Config.
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();

      // Get the secret keys from Firebase Remote Config.
      final secretKeyId = remoteConfig.getString('private_key_id');
      final secretKey = remoteConfig.getString('private_key');
      final smtpKey = remoteConfig.getString('smtp_key');

      // Create a SharedPreferences instance to store the keys.
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Save the keys to SharedPreferences for future use.
      prefs.setString("private_key_id", secretKeyId);
      prefs.setString("private_key", secretKey);
      prefs.setString("smtp_key", smtpKey);

      // Print a message to confirm that the keys have been saved.
      print("Keys saved to shared preferences");
    }
  } catch (e) {
    // Handle any errors that occur during the process.
    print("Error getting keys: ${e.toString()}");
  }
}

// This function requests various permissions and prints whether they are granted or not.

Future<void> checkPermission() async {
  // Request storage permission
  var storageStatus = await Permission.storage.request();

  if (storageStatus != PermissionStatus.granted) {
    // Storage permission not granted
    print('Storage Permission not granted');
  } else {
    // Storage permission granted
    print('Storage Permission granted');
  }

  // Request notification permission
  var notificationStatus = await Permission.notification.request();

  if (notificationStatus != PermissionStatus.granted) {
    // Notification permission not granted
    print('Notification Permission not granted');
  } else {
    // Notification permission granted
    print('Notification Permission granted');
  }

  // Request microphone permission
  var microphoneStatus = await Permission.microphone.request();

  if (microphoneStatus != PermissionStatus.granted) {
    // Microphone permission not granted
    print('Microphone Permission not granted');
  } else {
    // Microphone permission granted
    print('Microphone Permission granted');
  }
}

// This function initializes and sets default values for shared preferences.
void initSharedPreferences() async {
  // Get an instance of SharedPreferences for storing user preferences.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Initialize Firebase Cloud Messaging.
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Check if the "notification" preference is not set (null).
  if (prefs.getBool("notification") == null) {
    // Set the "notification" preference to true by default.
    prefs.setBool("notification", true);

    // Check if a user is logged in.
    if (FirebaseAuth.instance.currentUser != null) {
      // Subscribe the user to a notification topic using their UID.
      messaging.subscribeToTopic(FirebaseAuth.instance.currentUser!.uid);
    }
  }

  // Check if the "language" preference is not set (null).
  if (prefs.getString("language") == null) {
    // Set the "language" preference to "English" by default.
    prefs.setString("language", "English");
  }
}

// Function to initialize Firebase Cloud Messaging (FCM) for notifications
void initNotification() async {
  // Create an instance of FirebaseMessaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Subscribe to the "general" topic for receiving notifications
  messaging.subscribeToTopic("general");

  // Request notification permissions from the user
  NotificationSettings settings = await messaging.requestPermission(
    alert: true, // Allow displaying alerts
    announcement: false, // Do not allow announcements
    badge: true, // Show badges on app icon
    carPlay: false, // Disable CarPlay notifications
    criticalAlert: false, // Do not allow critical alerts
    provisional: false, // Notifications are not provisional
    sound: true, // Allow playing notification sounds
  );

  // Print the user's permission status for notifications
  print('User granted permission: ${settings.authorizationStatus}');
  print("Notification initialization completed");

  // Listen for incoming FCM messages when the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("You received a message");
    print("onMessage: ${message.notification?.body}");
    print("onMessage: ${message.data}");
  });
}

// Function to handle FCM messages when the app is in the background
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
        primaryColor: Color(0xFF6A1B9A),
      ),
      title: 'Ilili',
      initialRoute: '/',
      routes: {
        '/': (context) => GetStartedPage(),
        '/privacypolicy': (context) => PrivacyPolicyPage(),
        '/termsofservice': (context) => TermsOfServicePage(),
      },
    );
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
      initialRoute: '/',
      routes: {
        '/': (context) => AppRouter(
              index: 0,
            ),
        '/privacypolicy': (context) => PrivacyPolicyPage(),
        '/termsofservice': (context) => TermsOfServicePage(),
        '/profilepage': (context) => AppRouter(
              index: 2,
            ),
        '/addpost': (context) => AddPostPage(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}
