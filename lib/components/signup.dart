import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ilili/components/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference usersCollection = firestore.collection('users');
FirebaseAuth auth = FirebaseAuth.instance;

class SignupPage extends StatelessWidget {
  SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [
            Color(0xFF6A1B9A),
            Color(0xFFCD7CFF),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        )),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LogoSection(),
            SizedBox(height: 20),
            TitleSection(),
            SizedBox(height: 20),
            FormSection(),
            SizedBox(height: 20),
            ToLogin(),
          ],
        ),
      )),
    );
  }
}

class LogoSection extends StatelessWidget {
  LogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(
          image: AssetImage('assets/images/logo.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class TitleSection extends StatelessWidget {
  const TitleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("ilili",
            style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        SizedBox(width: 10),
        Text("signup",
            style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.w900,
                color: Color(0xFF009688))),
      ],
    );
  }
}

class FormSection extends StatefulWidget {
  FormSection({super.key});

  @override
  _FormSectionState createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSection> {
  TextEditingController emailController = TextEditingController();
  TextEditingController birthdateController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmationController =
      TextEditingController();
  late DateTime selectedDate = DateTime.now();
  bool passwordSame = false;
  bool error = false;
  String errorMessage = "";

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> signup() async {
    if (emailController.text == '' ||
        passwordController.text == '' ||
        passwordConfirmationController.text == '' ||
        selectedDate.toString() == '') {
      setState(() {
        error = true;
        errorMessage = "All fields must be filled";
      });
      return;
    }

    int age = DateTime.now().year - selectedDate.year;
    if (DateTime.now().month < selectedDate.month ||
        (DateTime.now().month == selectedDate.month &&
            DateTime.now().day < selectedDate.day)) {
      age--;
    }
    if (age < 18) {
      setState(() {
        error = true;
        errorMessage = "You must be at least 18 years old";
      });
      return;
    }

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      String uid = userCredential.user?.uid ?? '';

      await firestore.collection('users').doc(uid).set({
        'birthdate': DateFormat('yyyy-MM-dd').format(selectedDate),
      });

      print('User signed up and document created successfully!');
      setState(() {
        error = false;
        errorMessage = "";
      });
    } catch (e) {
      print('Error signing up user and creating document: $e');
      setState(() {
        error = true;
        errorMessage = e.toString().split('] ')[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      child: Column(
        children: [
          if (error)
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 5),
                  Container(
                    width: 250,
                    child: Text(
                      "${errorMessage}",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.email),
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            onTap: () {
              _selectDate(context);
            },
            readOnly: true,
            controller: TextEditingController(
              text: selectedDate != null
                  ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                  : '',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.calendar_month),
              labelText: 'Birthdate',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            obscureText: true,
            controller: passwordController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.lock),
              labelText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            obscureText: true,
            controller: passwordConfirmationController,
            onChanged: (value) {
              if (passwordController.text == value) {
                setState(() {
                  passwordSame = false;
                });
              } else {
                setState(() {
                  passwordSame = true;
                });
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.lock),
              labelText: 'Password Confirmation',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SizedBox(height: 10),
          if (passwordSame)
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 5),
                  Container(
                    width: 250,
                    child: Text(
                      'Password and password confirmation must be the same',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ElevatedButton(
            onPressed: () {
              signup();
            },
            child: Text('Signup'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              fixedSize:
                  Size(200, 50), // Set the width and height of the button
              backgroundColor:
                  Color(0xFF009688), // Set the background color of the button
            ),
          ),
        ],
      ),
    );
  }
}

class ToLogin extends StatelessWidget {
  const ToLogin({super.key});

  void redirectToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        redirectToLogin(context);
      },
      child: Text("Already have an account? Login"),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
            Colors.transparent), // Set the background color to transparent
        elevation: MaterialStateProperty.all<double>(
            0), // Remove the button's elevation
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                8), // Customize the button's border radius as desired
            side: BorderSide(
                color: Colors.transparent), // Remove the button's border
          ),
        ),
      ),
    );
  }
}
