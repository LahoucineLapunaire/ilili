import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

String username = "";
String profilePicture =
    "https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=8aa7825f-2890-4f63-9fb2-e66e7e916256";
String description = "";
bool isPhotoChanged = false;

class ChangeProfilePage extends StatelessWidget {
  const ChangeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ProfilPictureSection(),
          Text("Change Profile Page"),
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
      profilePicture = ds.get('profilPicture');
      print("profilePicture: " + profilePicture);
    });
  }

  void pickImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
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
