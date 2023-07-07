import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

String username = "";
String profilePicture = "";
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
  File? _image;
  final picker = ImagePicker();

  void getProfilePhoto() async {}

  Future getImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
