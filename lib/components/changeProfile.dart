import 'package:Ilili/components/widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Ilili/components/appRouter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;
FirebaseStorage storage = FirebaseStorage.instance;

String username = "";
String profilePicture =
    "https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=8aa7825f-2890-4f63-9fb2-e66e7e916256";
String description = "";
bool isPhotoChanged = false;
TextEditingController usernameController = TextEditingController();
TextEditingController descriptionController = TextEditingController();

class ChangeProfilePage extends StatelessWidget {
  const ChangeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFFAFAFA),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            "Profile",
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        backgroundColor: Color(0xFFFAFAFA),
        body: SingleChildScrollView(
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeaderSection(),
              SizedBox(height: 25),
              ProfilPictureSection(),
              SizedBox(height: 25),
              UserInfoWidget(),
              SizedBox(height: 25),
              ChangeInfoButton(),
            ],
          )),
        ));
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20),
      width: double.maxFinite,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "Account Information",
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "You can change your profile picture, username and description here",
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        )
      ]),
    );
  }
}

class ProfilPictureSection extends StatefulWidget {
  const ProfilPictureSection({super.key});

  @override
  State<ProfilPictureSection> createState() => _ProfilPictureSectionState();
}

class _ProfilPictureSectionState extends State<ProfilPictureSection> {
  File? image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getProfilePhoto();
  }

  // This function retrieves the profile photo URL from Firestore.
  void getProfilePhoto() async {
    // Fetch the document containing user data from Firestore.
    DocumentSnapshot ds =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    // Update the state to display the retrieved profile photo URL.
    setState(() {
      profilePicture = ds.get('profilePicture');
    });
  }

// This function allows the user to pick an image from their device's gallery.
  void pickImage() async {
    // Show the gallery and allow the user to select an image.
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    // Update the state with the selected image and set the 'isPhotoChanged' flag.
    setState(() {
      if (pickedFile != null) {
        // If an image was picked, assign it to the 'image' variable.
        image = File(pickedFile.path);
        isPhotoChanged = true;
        // Update the 'profilePicture' with the path to the picked image.
        profilePicture = pickedFile.path;
      } else {
        // If no image was selected, log a message.
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        pickImage();
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: image == null
              ? Image.network(
                  profilePicture,
                  fit: BoxFit.cover,
                )
              : kIsWeb
                  ? Image.network(
                      image!.path, // Replace with your asset path
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      image!,
                      fit: BoxFit.cover,
                    ),
        ),
      ),
    );
  }
}

class UserInfoWidget extends StatefulWidget {
  UserInfoWidget({Key? key});

  @override
  _UserInfoWidgetState createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  List<String> usernameList = [];
  String error = "";

  @override
  void initState() {
    super.initState();
    getUserInfo();
    getAllUsername();
  }

  // This function retrieves the user's information from Firestore and updates the UI.
  Future<void> getUserInfo() async {
    // Get the document snapshot of the current user from the 'users' collection in Firestore.
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get();

    // Check if the document exists.
    if (snapshot.exists) {
      // Update the state variables with the user's information.
      setState(() {
        username = snapshot.data()!['username'] ?? '';
        usernameController.text = snapshot.data()!['username'] ?? '';
        descriptionController.text = snapshot.data()!['description'] ?? '';
      });
    }
  }

// This function retrieves all usernames from Firestore and populates the 'usernameList' variable.
  Future<void> getAllUsername() async {
    // Query Firestore to get all documents in the 'users' collection.
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection("users").get();

    // Iterate through the documents and add usernames to the 'usernameList'.
    for (int i = 0; i < querySnapshot.docs.length; i++) {
      usernameList.add(querySnapshot.docs[i].get('username'));
    }
  }

// This function checks if a string contains spaces or special characters.
  bool containsSpacesOrSpecialCharacters(String input) {
    // Define a regular expression to match non-word characters (special characters).
    RegExp regex = RegExp(r'[^\w,]');
    return regex.hasMatch(input);
  }

// This function checks the validity of a username.
  bool checkUsername() {
    // Check if the entered username matches the current username.
    if (username == usernameController.text) {
      setState(() {
        error = "";
      });
      return true;
    }

    // Check if the entered username already exists in 'usernameList'.
    if (usernameList.contains(usernameController.text)) {
      setState(
        () {
          error = "Username already exists";
        },
      );
      return false;
    }

    // Check if the entered username contains spaces or special characters.
    if (containsSpacesOrSpecialCharacters(usernameController.text)) {
      setState(
        () {
          error = "Username cannot contain spaces or special characters";
        },
      );
      return false;
    }

    // Check if the entered username is too long (more than 20 characters).
    if (usernameController.text.length > 20) {
      setState(
        () {
          error = "Username cannot be more than 20 characters";
        },
      );
      return false;
    }

    // If all checks pass, clear the error message and return true.
    setState(
      () {
        error = "";
      },
    );
    return true;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 300,
          child: TextField(
            controller: usernameController,
            maxLength: 20,
            onChanged: (value) {
              checkUsername();
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.person),
              labelText: 'Username',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        SizedBox(height: 5),
        if (error != "")
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 5),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      color: Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        SizedBox(height: 15),
        Container(
          height: 200,
          width: 300,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              TextField(
                maxLines: null,
                controller: descriptionController,
                maxLength: 250,
                decoration: InputDecoration(
                  hintMaxLines: null,
                  border: InputBorder.none,
                  counterText: "",
                  hintText: 'Write your description ...',
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    '${descriptionController.text.length}/250',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChangeInfoButton extends StatefulWidget {
  const ChangeInfoButton({super.key});

  @override
  State<ChangeInfoButton> createState() => _ChangeInfoButtonState();
}

class _ChangeInfoButtonState extends State<ChangeInfoButton> {
  Reference storageRef = storage.ref("users");
  Reference webStorageRef =
      storage.refFromURL("gs://ilili-7ebc6.appspot.com/users");
  List<String> usernameList = [];

  @override
  void initState() {
    super.initState();
    getAllUsername();
  }

  // Function to retrieve all usernames from Firestore
  Future<void> getAllUsername() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection("users").get();

    for (int i = 0; i < querySnapshot.docs.length; i++) {
      // Add each username to the usernameList
      usernameList.add(querySnapshot.docs[i].get('username'));
    }
  }

// Function to check if a string contains spaces or special characters
  bool containsSpacesOrSpecialCharacters(String input) {
    RegExp regex = RegExp(r'[^\w,]');
    return regex.hasMatch(input);
  }

// Function to check if a username is valid
  bool checkUsername() {
    if (containsSpacesOrSpecialCharacters(usernameController.text)) {
      // Display an error message if the username contains invalid characters
      showErrorMessage(
          "Username cannot contain spaces or special characters", context);
      return false;
    }
    if (usernameController.text.length > 20) {
      // Display an error message if the username is too long
      showErrorMessage("Username cannot be longer than 20 characters", context);
      return false;
    }
    if (usernameController.text == "") {
      // Display an error message if the username is empty
      showErrorMessage("Username cannot be empty", context);
      return false;
    } else {
      return true;
    }
  }

// Function to change user information
  void changeUserInfo() async {
    try {
      if (usernameController.text == "" || descriptionController.text == "") {
        // Display an error message if any field is empty
        showErrorMessage("Please fill in all fields", context);
        return;
      }
      if (checkUsername() == false) {
        return;
      }
      if (usernameList.contains(usernameController.text) &&
          username != usernameController.text) {
        // Display an error message if the username already exists
        showErrorMessage("Username already exists", context);
        return;
      }
      if (profilePicture.isEmpty) {
        // Display an error message if no profile picture is selected
        showErrorMessage("Please select a profile picture", context);
        return;
      }
      if (descriptionController.text.length > 170) {
        // Display an error message if the description is too long
        showErrorMessage(
            "Description cannot be longer than 170 characters", context);
        return;
      }
      if (isPhotoChanged) {
        Reference imageRef;
        if (kIsWeb) {
          // Set the image reference for web
          imageRef = webStorageRef.child(auth.currentUser!.uid + ".jpg");
        } else {
          // Set the image reference for mobile
          imageRef = storageRef.child(auth.currentUser!.uid + ".jpg");
        }
        UploadTask uploadTask;
        if (kIsWeb) {
          // Upload image data for web
          Uint8List imageData = await XFile(profilePicture).readAsBytes();
          uploadTask = imageRef.putData(imageData);
        } else {
          // Upload image file for mobile
          uploadTask = imageRef.putFile(File(profilePicture));
        }

        await uploadTask.whenComplete(() async {
          print("Image uploaded !");
          String downloadURL = await imageRef.getDownloadURL();
          firestore.collection('users').doc(auth.currentUser!.uid).update({
            'username': usernameController.text,
            'description': descriptionController.text,
            'profilePicture': downloadURL,
          });
        });
      } else {
        // Update user information without changing the profile picture
        firestore.collection('users').doc(auth.currentUser!.uid).update({
          'username': usernameController.text,
          'description': descriptionController.text,
        });
      }
      // Clear text controllers and show a success message
      usernameController.clear();
      descriptionController.clear();
      showInfoMessage("User info changed !", context, () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
      // Navigate to a different page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppRouter(index: 2),
        ),
      );
    } catch (e) {
      if (kIsWeb) {
        // Print error message for web
        print("error : ${e.toString()}");
      } else {
        // Display error message for mobile
        showErrorMessage(e.toString().split('] ')[1], context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        changeUserInfo();
      },
      child: Text('Save modifications'),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: Size(250, 50), // Set the width and height of the button
        backgroundColor:
            Color(0xFF6A1B9A), // Set the background color of the button
      ),
    );
  }
}
