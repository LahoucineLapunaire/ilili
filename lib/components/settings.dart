import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/PrivacyPolicy.dart';
import 'package:Ilili/components/changeProfile.dart';
import 'package:Ilili/components/legalNotice.dart';
import 'package:Ilili/components/resetEmail.dart';
import 'package:Ilili/components/resetPassword.dart';
import 'package:Ilili/components/termsOfService.dart';
import 'package:Ilili/components/widget.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      // Access the Firestore collection "users" and get the document with the current user's UID.
      firestore
          .collection("users")
          .doc(auth.currentUser?.uid)
          .get()
          .then((value) {
        // Use a callback function to handle the result of the Firestore query.
        setState(() {
          // Set the "username" state variable to the value obtained from Firestore.
          // Note: value.data()?['username'] is used to safely access the 'username' field in the Firestore document.
          username = value.data()?['username'];
        });
      });
    } catch (e) {
      // Handle any errors that may occur during this operation.
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFAFA),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            "Settings",
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: const [
              ProfileSection(),
              Divider(
                height: 1,
                thickness: 1,
              ),
              if (!kIsWeb) NotificationSection(),
              if (!kIsWeb)
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
        ));
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.account_circle), // Icon on the left side
          title: Text(
            'Account Settings', // Text for the title
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        ListTile(
            title: const Text("Account information"),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => (const ChangeProfilePage())));
            }),
        ListTile(
          title: const Text("Change email"),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => (const ResetEmail())));
          },
        ),
        ListTile(
          title: const Text("Change password"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => (const ResetPassword())));
          },
        ),
      ],
    );
  }
}

class NotificationSection extends StatefulWidget {
  const NotificationSection({super.key});

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  bool notification = false;
  @override
  void initState() {
    super.initState();
    getNotificationState();
  }

  // Function to retrieve the notification state from SharedPreferences
  void getNotificationState() async {
    try {
      // Get an instance of SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Set the 'notification' variable to the stored boolean value, defaulting to true if not found
      setState(() {
        notification = prefs.getBool("notification") ?? true;
      });
    } catch (e) {
      // Handle any errors that occur during SharedPreferences retrieval
      print("Error: $e");
    }
  }

// Function to set values in SharedPreferences and subscribe/unsubscribe from topics
  void setValues(String pref, bool value) async {
    try {
      
      // Get an instance of Firebase Messaging
      var messaging = FirebaseMessaging.instance;  

      // Get an instance of SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Set the boolean preference with the given key to the provided value
      prefs.setBool(pref, value);

      // Update the 'notification' variable with the new value
      setState(() {
        notification = value;
      });

      // Subscribe or unsubscribe from topics based on the new value
      if (value) {
        messaging.subscribeToTopic(auth.currentUser!.uid);
        messaging.subscribeToTopic("general");
        print("Subscribed to topic ${auth.currentUser!.uid}");
      } else {
        messaging.unsubscribeFromTopic(auth.currentUser!.uid);
        messaging.unsubscribeFromTopic("general");
        print("Unsubscribed from topic ${auth.currentUser!.uid}");
      }
    } catch (e) {
      // Handle any errors that occur during SharedPreferences update or topic subscription
      print("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.notifications), // Icon on the left side
          title: Text(
            'Notifications', // Text for the title
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        ListTile(
          title: Text(
            "Turn on/off notifications",
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
          subtitle: Text(
              "Turn on/off notifications about followers, chat and comments",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
              )),
          trailing: Switch(
            activeColor: const Color(0xFF6A1B9A),
            value: notification,
            onChanged: (value) {
              setValues("notification", value);
            },
          ),
        ),
      ],
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

  @override
  void initState() {
    super.initState();
    getLanguage();
  }

  // Function to retrieve the selected language preference from SharedPreferences.
  void getLanguage() async {
    try {
      // Access the SharedPreferences instance to store key-value pairs.
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Use setState to update the selectedLanguage variable with the stored value.
      setState(() {
        selectedLanguage = prefs.getString("language") ?? 'English';
        // If no language preference is found in SharedPreferences, default to 'English'.
      });
    } catch (e) {
      // Handle any errors that may occur during SharedPreferences access.
      print("Error: $e");
    }
  }

// Function to set the user's preferred language in SharedPreferences.
  void setLanguage(String value) async {
    // Access the SharedPreferences instance to store key-value pairs.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Store the selected language preference with the key "language".
    prefs.setString("language", value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.app_settings_alt), // Icon on the left side
          title: Text(
            'General Settings', // Text for the title
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
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
    );
  }
}

class SubscriptionSection extends StatelessWidget {
  const SubscriptionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.monetization_on), // Icon on the left side
          title: Text(
            'Subscription', // Text for the title
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        ListTile(
          title: Text("Available soon",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
              )),
          subtitle: subscription
              ? Text("You are subscribed to ilili subsciption",
                  style: TextStyle(
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ))
              : Text("You are not subscribed to ilili subsciption",
                  style: TextStyle(
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  )),
        )
      ],
    );
  }
}

class HelpSection extends StatelessWidget {
  const HelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.help_rounded), // Icon on the left side
          title: Text(
            'Help and Support', // Text for the title
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        ListTile(
          title: Text("Contact support",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
              )),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => const ContactSupportModal(),
            );
          },
        ),
        ListTile(
          title: Text("View FAQs or Help Center",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
              )),
        ),
        ListTile(
          title: Text("Report a problem or bug",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
              )),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => const ReportProblemModal(),
            );
          },
        ),
      ],
    );
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info), // Icon on the left side
          title: Text(
            'About and Legal', // Text for the title
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        ListTile(
          title: Text("Legal Notice",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
              )),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => (LegalNoticePage())));
          },
        ),
        ListTile(
          title: Text("Terms of Service",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
              )),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => (TermsOfServicePage())));
          },
        ),
        ListTile(
          title: Text("Privacy Policy",
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
              )),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => (PrivacyPolicyPage())));
          },
        ),
      ],
    );
  }
}

class LogoutSection extends StatelessWidget {
  const LogoutSection({super.key});

  void showConfirmAlert(BuildContext context) {
    // Create a AlertDialog
    AlertDialog alertDialog = AlertDialog(
      title: const Text("Do you want to logout ?"),
      actions: [
        // OK button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
          ),
          child: const Text('No', style: TextStyle(color: Colors.black)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
          ),
          child: const Text('Yes', style: TextStyle(color: Colors.white)),
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

// Function to log the user out
  void logout() async {
    try {
      // Sign out the user from Firebase authentication
      auth.signOut();

      // Create an instance of GoogleSignIn
      final googleSignIn = GoogleSignIn();

      // Sign out the user from Google Sign-In
      await googleSignIn.signOut();
    } catch (e) {
      // Handle any exceptions that may occur during the logout process
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
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
          fontFamily: GoogleFonts.poppins().fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red,
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

  // Function to send a support message
  void sendSupportMessage() async {
    try {
      // Get user preferences
      final prefs = await SharedPreferences.getInstance();
      // Retrieve SMTP key from preferences or use an empty string as default
      var smtpkey = prefs.getString('smtp_key') ?? '';
      // Define the SMTP server using Gmail
      final smtpServer = gmail('moderation.ilili@gmail.com', smtpkey);

      // Create a message
      final message = Message()
        ..from = Address(
            auth.currentUser!.email ?? "", auth.currentUser?.displayName)
        ..recipients.add('moderation.ilili@gmail.com')
        ..subject = '[Support] ${objectController.text}' // Subject of the email
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
  h2 {
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
<h1>Support message from $username (uid: ${auth.currentUser?.uid}) (email: ${auth.currentUser?.email})</h1>
<h2>Object: ${objectController.text}</h2>
<p>${messageController.text}</p>
</body>
</html>
'''; // HTML content of the email

      // Send the email using the specified SMTP server
      final sendReport = await send(message, smtpServer);

      // Show a success message
      showInfoMessage("Your message has been correctly sent", context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });

      // Print a confirmation message to the console
      print('Message sent: ${sendReport.toString()}');

      // Close the current screen or navigate back
      Navigator.pop(context);
    } catch (e) {
      // Handle any errors that occur during the email sending process
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
        height: 500,
        child: Column(
          children: [
            if (kIsWeb)
              const Text(
                "If you are using the web version of Ilili, please contact us at moderation.ilili@gmail.com",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (kIsWeb) const SizedBox(height: 10),
            const Text(
              "Contact support, please tell us your questions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: objectController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Object',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                maxLines: null,
                controller: messageController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write your message ...',
                ),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                sendSupportMessage();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fixedSize: const Size(
                    180, 35), // Set the width and height of the button
                backgroundColor: const Color(
                    0xFF6A1B9A), // Set the background color of the button
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 10),
                    Text("Send")
                  ]),
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
      // Retrieve SMTP key from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var smtpkey = prefs.getString('smtp_key') ?? '';

      // Configure the SMTP server for sending emails (using Gmail)
      final smtpServer = gmail('moderation.ilili@gmail.com', smtpkey);

      // Create an email message
      final message = Message()
        // Set the sender's email and display name (if available)
        ..from = Address(
            auth.currentUser!.email ?? "", auth.currentUser?.displayName)
        // Add the recipient's email address
        ..recipients.add('moderation.ilili@gmail.com')
        // Set the subject of the email
        ..subject = '[Problem] ${objectController.text}'
        // Define the email content as an HTML template
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
  h2 {
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
<h1>Problem message from $username (uid: ${auth.currentUser?.uid}) (email: ${auth.currentUser?.email})</h1>
<h2>Object: ${objectController.text}</h2>
<p>${messageController.text}</p>
</body>
</html>
''';

      // Send the email using the configured SMTP server
      final sendReport = await send(message, smtpServer);

      // Display a success message to the user
      showInfoMessage("Your message has been correctly sent", context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });

      // Print a message indicating that the email was sent successfully
      print('Message sent: ${sendReport.toString()}');

      // Close the current screen (assuming this function is used in a screen)
      Navigator.pop(context);
    } catch (e) {
      // Handle any errors that occur during the email sending process
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
        height: 500,
        child: Column(
          children: [
            if (kIsWeb)
              const Text(
                "If you are using the web version of Ilili, please contact us at moderation.ilili@gmail.com",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (kIsWeb) const SizedBox(height: 10),
            const Text(
              "Please describe your problem or the bug you have encountered",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: objectController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Object',
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                maxLines: null,
                controller: messageController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'describe the problem ...',
                ),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                sendReportProblem();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                fixedSize: const Size(
                    180, 35), // Set the width and height of the button
                backgroundColor: const Color(
                    0xFF6A1B9A), // Set the background color of the button
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 10),
                    Text("Send")
                  ]),
            )
          ],
        ),
      ),
    );
  }
}
