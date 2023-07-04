import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ilili/components/appRouter.dart';
import 'package:ilili/components/emailNotVerified.dart';
import 'components/signup.dart';

FirebaseAuth auth = FirebaseAuth.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
