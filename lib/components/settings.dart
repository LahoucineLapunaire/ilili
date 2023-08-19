import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ilili/components/PrivacyPolicy.dart';
import 'package:ilili/components/changeProfile.dart';
import 'package:ilili/components/legalnotice.dart';
import 'package:ilili/components/resetEmail.dart';
import 'package:ilili/components/resetPassword.dart';
import 'package:ilili/components/subscription.dart';
import 'package:ilili/components/termsOfService.dart';
import 'package:ilili/components/widget.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:shared_preferences/shared_preferences.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;
String username = "";
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
          username = value.data()?['username'];
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
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => ContactSupportModal(),
              );
            },
          ),
          ListTile(
            title: Text("View FAQs or Help Center"),
          ),
          ListTile(
            title: Text("Report a problem or bug"),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => ReportProblemModal(),
              );
            },
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
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => (LegalNoticePage())));
            },
          ),
          ListTile(
            title: Text("Terms of Service"),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => (TermsOfServicePage())));
            },
          ),
          ListTile(
            title: Text("Privacy Policy"),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => (PrivacyPolicyPage())));
            },
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

class ContactSupportModal extends StatefulWidget {
  const ContactSupportModal({super.key});

  @override
  State<ContactSupportModal> createState() => _ContactSupportModalState();
}

class _ContactSupportModalState extends State<ContactSupportModal> {
  TextEditingController objectController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  void sendSupportMessage() async {
    try {
      final smtpServer =
          gmail('moderation.ilili@gmail.com', 'gpubnhzldelidwcq');

      // Create a message
      final message = Message()
        ..from = Address(
            auth.currentUser!.email ?? "", auth.currentUser?.displayName)
        ..recipients.add('moderation.ilili@gmail.com')
        ..subject = '[Support] ${objectController.text}'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
<style>
  body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 0;
  }
  h1 {
    color: #333333;
    font-size: 24px;
    margin-bottom: 10px;
  }
  h1 {
    color: #0066ff;
    font-size: 20px;
    margin-bottom: 10px;
  }
  p {
    color: #666666;
    font-size: 16px;
    line-height: 1.5;
  }
</style>
</head>
<body>
<h1>Support message from ${username} (uid: ${auth.currentUser?.uid}) (email: ${auth.currentUser?.email})</h1>
<h2>Object: ${objectController.text}</h2>
<p>${messageController.text}</p>
</body>
</html>
''';
      final sendReport = await send(message, smtpServer);
      showInfoMessage("Your message has been correctly sent", context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
      print('Message sent: ${sendReport.toString()}');
      Navigator.pop(context);
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
        height: 500,
        child: Column(
          children: [
            Text(
              "Contact support, please tell us your questions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: objectController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Object',
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                maxLines: null,
                controller: messageController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write your message ...',
                ),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                sendSupportMessage();
              },
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 10),
                    Text("Send")
                  ]),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fixedSize:
                    Size(180, 35), // Set the width and height of the button
                backgroundColor:
                    Color(0xFF6A1B9A), // Set the background color of the button
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ReportProblemModal extends StatefulWidget {
  const ReportProblemModal({super.key});

  @override
  State<ReportProblemModal> createState() => _ReportProblemModalState();
}

class _ReportProblemModalState extends State<ReportProblemModal> {
  TextEditingController objectController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  void sendReportProblem() async {
    try {
      final smtpServer =
          gmail('moderation.ilili@gmail.com', 'gpubnhzldelidwcq');

      // Create a message
      final message = Message()
        ..from = Address(
            auth.currentUser!.email ?? "", auth.currentUser?.displayName)
        ..recipients.add('moderation.ilili@gmail.com')
        ..subject = '[Problem] ${objectController.text}'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
<style>
  body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 0;
  }
  h1 {
    color: #333333;
    font-size: 24px;
    margin-bottom: 10px;
  }
  h1 {
    color: #0066ff;
    font-size: 20px;
    margin-bottom: 10px;
  }
  p {
    color: #666666;
    font-size: 16px;
    line-height: 1.5;
  }
</style>
</head>
<body>
<h1>Problem message from ${username} (uid: ${auth.currentUser?.uid}) (email: ${auth.currentUser?.email})</h1>
<h2>Object: ${objectController.text}</h2>
<p>${messageController.text}</p>
</body>
</html>
''';
      final sendReport = await send(message, smtpServer);
      showInfoMessage("Your message has been correctly sent", context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
      print('Message sent: ${sendReport.toString()}');
      Navigator.pop(context);
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
        height: 500,
        child: Column(
          children: [
            Text(
              "Please describe your problem or the bug you have encountered",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: objectController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Object',
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                maxLines: null,
                controller: messageController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'describe the problem ...',
                ),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                sendReportProblem();
              },
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 10),
                    Text("Send")
                  ]),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fixedSize:
                    Size(180, 35), // Set the width and height of the button
                backgroundColor:
                    Color(0xFF6A1B9A), // Set the background color of the button
              ),
            )
          ],
        ),
      ),
    );
  }
}
