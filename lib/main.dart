import 'package:flutter/material.dart';
import 'components/home.dart';
import 'components/login.dart';
import 'components/signup.dart';

bool logged = true;

void main() {
  if (logged)
    runApp(Logged());
  else
    runApp(UnLogged());
}

class UnLogged extends StatelessWidget {
  const UnLogged({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'UnLogged',
        home: Scaffold(
          body: SignupPage(),
        ));
  }
}

class Logged extends StatelessWidget {
  const Logged({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logged',
      home: HomePage(),
    );
  }
}
