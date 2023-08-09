import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ilili/components/widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ilili/components/appRouter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:io';

List<String> tagsList = [];
AudioPlayer audioPlayer = AudioPlayer();
String audioPath = '';
FirebaseAuth auth = FirebaseAuth.instance;
FirebaseStorage storage = FirebaseStorage.instance;

class AddPostPage extends StatelessWidget {
  const AddPostPage({super.key});

  @override
  void dispose() {
    audioPlayer.release();
    audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Text(
                  "To add a post, please record an audio file or upload one, and add some tags to it, and then click on the 'Add Post' button."),
            ),
            SizedBox(height: 10),
            ButtonSection(),
            SizedBox(height: 20),
            AudioPlayerSection(),
            Divider(
              height: 50,
              thickness: 2,
            ),
            TagsSection(),
            SizedBox(height: 20),
            SendButtonSection(),
          ],
        ),
      ),
    );
  }
}

class ButtonSection extends StatefulWidget {
  const ButtonSection({super.key});

  @override
  State<ButtonSection> createState() => _ButtonSectionState();
}

class _ButtonSectionState extends State<ButtonSection> {
  FlutterSoundRecorder? audioRecorder;
  FlutterSoundPlayer? player;
  bool isRecording = false;

  Future<bool> checkPermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    if (await Permission.microphone.request().isGranted) {
      print('Permission granted');
      return true;
    } else {
      print('Permission denied');
      return false;
    }
  }

  void startRecording() async {
    try {
      if (audioRecorder != null) {
        // Stop any ongoing recording before starting a new one
        await audioRecorder!.stopRecorder();
      }
      File existingFile = File('audio.aac');
      if (existingFile.existsSync()) {
        await existingFile.delete();
        print('Existing file deleted');
      }
      await checkPermission();
      print('--------------->Here1');
      audioRecorder = FlutterSoundRecorder();
      print('--------------->Here2');
      // Start recording audio
      await audioRecorder?.openRecorder();
      print('--------------->Here3');
      await audioRecorder!.startRecorder(toFile: 'audio.aac');
      print('--------------->Here4');
      setState(() {
        isRecording = true;
      });
    } catch (e) {
      showErrorMessage(e.toString(), context);
      print('Error starting recording: $e');
    }
  }

  void stopRecording() async {
    try {
      if (audioRecorder != null) {
        // Stop the ongoing recording
        await audioRecorder!.stopRecorder();
        await audioRecorder!.closeRecorder();
        audioRecorder = null;
        print("Recording stopped");
        setState(() {
          audioPath = 'audio.aac';
          isRecording = false;
        });

        String filePath = '/data/user/0/com.example.ilili/cache/audio.aac';
        audioPath = filePath;
      }
      ;
    } catch (e) {
      showErrorMessage(e.toString(), context);
      print('Error stopping recording or playing audio: $e');
    }
  }

  Future<void> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        print("File path: ${file.path}");
        setState(() {
          audioPath = file.path!;
          audioPlayer.setSourceUrl(file.path!);
        });
      }
    } catch (e) {
      showErrorMessage(e.toString(), context);
      print("Error while picking the file: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isRecording)
          ElevatedButton(
            onPressed: () {
              stopRecording();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stop),
                SizedBox(width: 5),
                Text('Stop Recording'),
              ],
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              fixedSize:
                  Size(170, 35), // Set the width and height of the button
              backgroundColor:
                  Color(0xFF6A1B9A), // Set the background color of the button
            ),
          ),
        if (!isRecording)
          ElevatedButton(
            onPressed: () {
              startRecording();
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.mic),
              SizedBox(width: 5),
              Text('Record Audio')
            ]),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              fixedSize:
                  Size(170, 35), // Set the width and height of the button
              backgroundColor:
                  Color(0xFF6A1B9A), // Set the background color of the button
            ),
          ),
        SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            pickAudioFile();
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.audiotrack),
            SizedBox(width: 5),
            Text('Pick Audio')
          ]),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            fixedSize: Size(170, 35), // Set the width and height of the button
            backgroundColor:
                Color(0xFF6A1B9A), // Set the background color of the button
          ),
        ),
      ],
    );
  }
}

class AudioPlayerSection extends StatefulWidget {
  AudioPlayerSection({super.key});

  @override
  State<AudioPlayerSection> createState() => AudioPlayerSectionState();
}

class AudioPlayerSectionState extends State<AudioPlayerSection> {
  bool isPlaying = false;
  Duration audioDuration = Duration();
  Duration position = Duration();

  void initState() {
    super.initState();
    audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        audioDuration = duration;
      });
    });

    audioPlayer.onPositionChanged.listen((Duration pos) {
      setState(() {
        position = pos;
      });
    });
  }

  void playPause() async {
    try {
      if (isPlaying) {
        await audioPlayer.pause();
        setState(() => isPlaying = false);
      } else {
        if (audioPath != null) {
          print(audioPath);
          await audioPlayer.play(UrlSource(audioPath));
          setState(() => isPlaying = true);
        }
      }
    } catch (e) {
      showErrorMessage(e.toString(), context);
    }
  }

  void _seekToSecond(int second) {
    Duration newDuration = Duration(seconds: second);
    audioPlayer.seek(newDuration);
  }

  String formatPosition(int position) {
    double result = position / 1000;
    String minutes = (result / 60).floor().toString();
    String secondes = (result % 60).floor().toString();
    return minutes + ':' + secondes;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                playPause();
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(formatPosition(position.inMilliseconds)),
                Slider(
                  activeColor: Color(0xFF6A1B9A),
                  inactiveColor: Color(0xFF6A1B9A).withOpacity(0.3),
                  min: 0.0,
                  max: audioDuration.inSeconds.toDouble(),
                  value: position.inSeconds.toDouble(),
                  onChanged: (double value) {
                    setState(() {
                      _seekToSecond(value.toInt());
                      value = value;
                    });
                  },
                ),
                Text(formatPosition(audioDuration.inMilliseconds)),
              ],
            )
          ],
        )
      ],
    );
  }
}

class TagsSection extends StatefulWidget {
  const TagsSection({super.key});

  @override
  State<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  TextEditingController tagController = TextEditingController();

  void addTag() {
    try {
      if (tagsList.contains(tagController.text)) {
        showErrorMessage("Tag already exists", context);
        return;
      }
      if (tagsList.length >= 3) {
        showErrorMessage("You can only add 3 tags", context);
        return;
      }
      if (tagController.text == "") {
        showErrorMessage("Tag can't be empty", context);
        return;
      }

      setState(() {
        tagsList.add(tagController.text);
      });
    } catch (e) {
      showErrorMessage(e.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      child: Column(
        children: [
          TextField(
            controller: tagController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  addTag();
                },
              ),
              labelText: 'tag',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: tagsList.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200, // Set the desired width here
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tagsList[index]),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          tagsList.removeAt(index);
                        });
                      },
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SendButtonSection extends StatefulWidget {
  SendButtonSection({Key? key}) : super(key: key);

  @override
  _SendButtonSectionState createState() => _SendButtonSectionState();
}

class _SendButtonSectionState extends State<SendButtonSection> {
  Reference storageRef = storage.ref("posts");
  String audioLink = "";

  String generateUniqueFileName() {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String randomString = path.basenameWithoutExtension(
        path.basenameWithoutExtension(path.basenameWithoutExtension(
            path.basenameWithoutExtension(path.basenameWithoutExtension(
                path.basenameWithoutExtension(path.basenameWithoutExtension(
                    path.basenameWithoutExtension(timestamp))))))));
    String fileName = 'audio_$randomString.aac';
    return fileName;
  }

  Future<List<dynamic>> getPosts() async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        String userId = user.uid;

        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('posts')
            .get();

        List<dynamic> posts = snapshot.docs.map((doc) => doc.data()).toList();

        return posts;
      }
    } catch (e) {
      showErrorMessage(e.toString(), context);
      print('Error getting posts: $e');
    }
    return [];
  }



  Future postAudio() async {
    try {
      String name = generateUniqueFileName();
      List<dynamic> posts = await getPosts();
      Reference postRef = storageRef.child(name);
      UploadTask uploadTask = postRef.putFile(File(audioPath));
      posts.add(name);

      await uploadTask.whenComplete(() async {
        String downloadURL = await postRef.getDownloadURL();

        FirebaseFirestore.instance.collection('posts').doc(name).set({
          'userId': auth.currentUser!.uid,
          'audio': downloadURL,
          'tags': tagsList,
          'likes': [],
          'comments': [],
          'timestamp': DateTime.now(),
          'score': 0,
        });

        FirebaseFirestore.instance
            .collection('users')
            .doc(auth.currentUser!.uid)
            .update({
          'posts': posts,
        });
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppRouter(),
        ),
      );
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        postAudio();
      },
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.send),
        SizedBox(width: 10),
        Text('Post Audio')
      ]),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        fixedSize: Size(170, 35), // Set the width and height of the button
        backgroundColor:
            Color(0xFF6A1B9A), // Set the background color of the button
      ),
    );
  }
}
