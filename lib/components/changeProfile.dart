import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ilili/components/appRouter.dart';
import 'package:ilili/components/signup.dart';
import 'package:ilili/components/widget.dart';
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
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Change Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Color(0xFFECEFF1),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ProfilPictureSection(),
          SizedBox(height: 20),
          UserInfoWidget(),
          SizedBox(height: 20),
          ChangeInfoButton(),
        ],
      )),
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

  void getProfilePhoto() async {
    DocumentSnapshot ds =
        await firestore.collection('users').doc(auth.currentUser!.uid).get();

    setState(() {
      profilePicture = ds.get('profilePicture');
      print("profilePicture: " + profilePicture);
    });
  }

  void pickImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
        isPhotoChanged = true;
        profilePicture = pickedFile.path;
      } else {
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
          borderRadius: BorderRadius.circular(50),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: image == null
              ? Image.network(
                  profilePicture,
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
  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get();

    if (snapshot.exists) {
      setState(() {
        usernameController.text = snapshot.data()!['username'] ?? '';
        descriptionController.text = snapshot.data()!['description'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    descriptionController.dispose();
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
        SizedBox(height: 15),
        Container(
          width: 300,
          child: Container(
            height: 200,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: descriptionController,
              maxLines: null,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Write your comment ...',
              ),
            ),
          ),
        )
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
  List<String> usernameList = [];

  @override
  void initState() {
    super.initState();
    getAllUsername();
  }

  Future<void> getAllUsername() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection("users").get();

    for (int i = 0; i < querySnapshot.docs.length; i++) {
      usernameList.add(querySnapshot.docs[i].get('username'));
      print("Username: ${querySnapshot.docs[i].get('username')}");
      ;
    }
  }

  bool containsSpacesOrSpecialCharacters(String input) {
    RegExp regex = RegExp(r'[^\w,]');
    return regex.hasMatch(input);
  }

  bool checkUsername() {
    if (containsSpacesOrSpecialCharacters(usernameController.text)) {
      showErrorMessage(
          "Username cannot contain spaces or special characters", context);
      return false;
    }
    if (usernameController.text.length > 20) {
      showErrorMessage("Username cannot be longer than 20 characters", context);
      return false;
    }
    if (usernameController.text == "") {
      showErrorMessage("Username cannot be empty", context);
      return false;
    } else {
      return true;
    }
  }

  void changeUserInfo() async {
    try {
      print("username: ${usernameController.text}");
      print("description: ${descriptionController.text}");
      print("profilePicture: $profilePicture");
      if (usernameController.text == "" || descriptionController.text == null) {
        showErrorMessage("Please fill in all fields", context);
        return;
      }
      if (checkUsername() == false) {
        return;
      }

      if (profilePicture.isEmpty) {
        showErrorMessage("Please select a profile picture", context);
        return;
      }
      if (descriptionController.text.length > 170) {
        showErrorMessage(
            "Description cannot be longer than 170 characters", context);
        return;
      }
      if (isPhotoChanged) {
        Reference imageRef = storageRef.child(auth.currentUser!.uid + ".jpg");
        UploadTask uploadTask = imageRef.putFile(File(profilePicture));
        await uploadTask.whenComplete(() async {
          String downloadURL = await imageRef.getDownloadURL();
          firestore.collection('users').doc(auth.currentUser!.uid).update({
            'username': usernameController.text,
            'description': descriptionController.text,
            'profilePicture': downloadURL,
          });
        });
      } else {
        firestore.collection('users').doc(auth.currentUser!.uid).update({
          'username': usernameController.text,
          'description': descriptionController.text,
        });
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppRouter(),
        ),
      );
    } catch (e) {
      showErrorMessage(e.toString().split('] ')[1], context);
      print("---------------------> ${e.toString().split('] ')[1]}");
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
        fixedSize: Size(200, 30), // Set the width and height of the button
        backgroundColor:
            Color(0xFF6A1B9A), // Set the background color of the button
      ),
    );
  }
}
