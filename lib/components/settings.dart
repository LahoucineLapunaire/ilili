import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ilili/components/changeProfile.dart';
import 'package:ilili/components/resetEmail.dart';
import 'package:ilili/components/resetPassword.dart';
import 'package:ilili/components/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;
bool subscription = false;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  void getUserInfo() {
    try {
      firestore
          .collection("users")
          .doc(auth.currentUser?.uid)
          .get()
          .then((value) {
        setState(() {
          subscription = value.data()?['subscription'];
        });
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: SingleChildScrollView(
          child: Container(
            child: Column(
              children: [
                ProfileSection(),
                Divider(
                  height: 1,
                  thickness: 1,
                ),
                NotificationSection(),
                Divider(
                  height: 1,
                  thickness: 1,
                ),
                AppSection(),
                Divider(
                  height: 1,
                  thickness: 1,
                ),
                SubscriptionSection(),
                Divider(
                  height: 1,
                  thickness: 1,
                ),
                HelpSection(),
                Divider(
                  height: 1,
                  thickness: 1,
                ),
                AboutSection(),
                Divider(
                  height: 1,
                  thickness: 1,
                ),
                LogoutSection(),
              ],
            ),
          ),
        ));
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.account_circle), // Icon on the left side
            title: Text(
              'Account Settings', // Text for the title
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ListTile(
              title: Text("Account information"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => (ChangeProfilePage())));
              }),
          ListTile(
            title: Text("Change email"),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => (ResetEmail())));
            },
          ),
          ListTile(
            title: Text("Change password"),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => (ResetPassword())));
            },
          ),
        ],
      ),
    );
  }
}

class NotificationSection extends StatefulWidget {
  const NotificationSection({super.key});

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  bool followers = true;
  bool chat = true;
  bool comments = true;

  void getNotificationState() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        followers = prefs.getBool("followerNotificaiton") ?? true;
        chat = prefs.getBool("chatNotificaiton") ?? true;
        comments = prefs.getBool("commentNotificaiton") ?? true;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  void setValues(String pref, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(pref, value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.notifications), // Icon on the left side
            title: Text(
              'Notifications', // Text for the title
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ListTile(
            title: Text("Followers"),
            subtitle: Text("Turn on/off notifications about followers"),
            trailing: Switch(
              value: followers,
              onChanged: (value) {
                setState(() {
                  followers = value;
                });
                setValues("followerNotificaiton", value);
              },
            ),
          ),
          ListTile(
            title: Text("Chat messages"),
            subtitle: Text("Turn on/off notifications about messages"),
            trailing: Switch(
              value: chat,
              onChanged: (value) {
                setState(() {
                  chat = value;
                });
                setValues("chatNotificaiton", value);
              },
            ),
          ),
          ListTile(
            title: Text("Comments"),
            subtitle: Text("Turn on/off notifications about comments"),
            trailing: Switch(
              value: comments,
              onChanged: (value) {
                setState(() {
                  comments = value;
                });
                setValues("commentNotificaiton", value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AppSection extends StatefulWidget {
  const AppSection({super.key});

  @override
  State<AppSection> createState() => _AppSectionState();
}

class _AppSectionState extends State<AppSection> {
  String selectedLanguage = 'English';
  final List<String> languageOptions = [
    'English',
  ];

  void initState() {
    super.initState();
    getLanguage();
  }

  void getLanguage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        selectedLanguage = prefs.getString("language") ?? 'English';
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  void setLanguage(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("language", value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.app_settings_alt), // Icon on the left side
            title: Text(
              'General Settings', // Text for the title
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          DropdownButton<String>(
            value: selectedLanguage,
            onChanged: (newValue) {
              setState(() {
                selectedLanguage = newValue!;
              });
              setLanguage(newValue!);
            },
            items: languageOptions.map((language) {
              return DropdownMenuItem<String>(
                value: language,
                child: Text(language),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class SubscriptionSection extends StatelessWidget {
  const SubscriptionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.monetization_on), // Icon on the left side
            title: Text(
              'Subscription', // Text for the title
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ListTile(
            title: Text("Available soon"),
            subtitle: subscription
                ? Text("You are subscribed to ilili subsciption")
                : Text("You are not subscribed to ilili subsciption"),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => (SubscriptionPage())));
            },
          )
        ],
      ),
    );
  }
}

class HelpSection extends StatelessWidget {
  const HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.help_rounded), // Icon on the left side
            title: Text(
              'Help and Support', // Text for the title
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ListTile(
            title: Text("Contact support"),
          ),
          ListTile(
            title: Text("View FAQs or Help Center"),
          ),
          ListTile(
            title: Text("Report a problem or bug"),
          ),
        ],
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info), // Icon on the left side
            title: Text(
              'About and Legal', // Text for the title
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ListTile(
            title: Text("Legal Notice"),
          ),
          ListTile(
            title: Text("Terms of Service"),
          ),
          ListTile(
            title: Text("Privacy Policy"),
          ),
        ],
      ),
    );
  }
}

class LogoutSection extends StatelessWidget {
  const LogoutSection({super.key});

  void showConfirmAlert(BuildContext context) {
    // Create a AlertDialog
    AlertDialog alertDialog = AlertDialog(
      title: Text("Do you want to logout ?"),
      actions: [
        // OK button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
          ),
          child: Text('No', style: TextStyle(color: Colors.black)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6A1B9A),
          ),
          child: Text('Yes', style: TextStyle(color: Colors.white)),
          onPressed: () {
            logout();
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    // Show the alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alertDialog;
      },
    );
  }

  void logout() {
    try {
      auth.signOut();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        onPressed: () {
          showConfirmAlert(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Set transparent background
          elevation: 0, // Remove elevation and shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // No border radius
          ),
        ),
        child: Text(
          "Logout",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
