import 'package:flutter/material.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/login.dart';
import 'package:Ilili/components/signup.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: SingleChildScrollView(
              child: Container(
        height: MediaQuery.of(context).size.height,
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
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          DelayedDisplay(
              delay: Duration(milliseconds: 500), child: LogoSection()),
          SizedBox(height: 100),
          DelayedDisplay(
              delay: Duration(milliseconds: 800),
              child: Text(
                "Ilili: Where your voice matters.",
                style: TextStyle(
                    fontFamily: GoogleFonts.poppins().fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              )),
          SizedBox(height: 20),
          DelayedDisplay(
              delay: Duration(milliseconds: 1200),
              child: Text(
                "Let's Get Started",
                style: TextStyle(
                    fontFamily: GoogleFonts.poppins().fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              )),
          SizedBox(height: 20),
          DelayedDisplay(
              delay: Duration(milliseconds: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Ilili is in a beta version, we are working hard to make it better. Please report any bug you find.",
                  style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      fontSize: 16,
                      color: Colors.white),
                ),
              )),
          SizedBox(height: 50),
          DelayedDisplay(
              delay: Duration(milliseconds: 1500), child: ButtonSetion()),
        ]),
      ))),
    );
    ;
  }
}

class LogoSection extends StatelessWidget {
  LogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(
          image: AssetImage('assets/images/ic_launcher.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class ButtonSetion extends StatelessWidget {
  const ButtonSetion({super.key});

  void redirect(BuildContext context, String name) {
    if (name == "login") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SignupPage()));
    }
    if (name == "signup") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF6A1B9A),
            minimumSize: Size(250, 50),
          ),
          onPressed: () => redirect(context, "login"),
          child: Text("Join Now !"),
        ),
        SizedBox(height: 20),
        ElevatedButton(
            onPressed: () => redirect(context, "signup"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: Size(250, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already an account ?",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  "Login",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ))
      ],
    );
  }
}
