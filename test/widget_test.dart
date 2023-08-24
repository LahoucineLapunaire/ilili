// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:Ilili/components/addPost.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Ilili/main.dart';

FirebaseAuth auth = FirebaseAuth.instance;

void main() {
  group('SendButtonSection', () {
    testWidgets('postAudio correctly posts audio', (WidgetTester tester) async {
      // Set up the necessary variables from addPost.dart.
      tagsList = [];
      audioPath = 'test_audio_path';
  
      titleController = TextEditingController(text: 'Test Title');

      // Create an instance of SendButtonSection.
      final sendButtonSection = SendButtonSection();

      // Call the postAudio function.
      await sendButtonSection.createState().postAudio();

      // Add your assertions here.
    });

    // More test cases...
  });
}






