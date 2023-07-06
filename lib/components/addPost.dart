import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

List<String> tagsList = [];
AudioPlayer audioPlayer = AudioPlayer();
String audioPath = '';

class AddPostPage extends StatelessWidget {
  const AddPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                "To add a post, please record an audio file or upload one, and add some tags to it, and then click on the 'Add Post' button."),
            SizedBox(height: 20),
            ButtonSection(),
            SizedBox(height: 20),
            AudioPlayerSection(),
            Divider(
              height: 50,
              thickness: 2,
            ),
            TagsSection(),
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
      audioRecorder = FlutterSoundRecorder();

      // Start recording audio
      await audioRecorder?.openRecorder();
      await audioRecorder!.startRecorder(toFile: 'audio.aac');
      setState(() {
        isRecording = true;
      });
    } catch (e) {
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
        });
      }
    } catch (e) {
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
                  Size(150, 30), // Set the width and height of the button
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
                  Size(150, 30), // Set the width and height of the button
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
            fixedSize: Size(150, 30), // Set the width and height of the button
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
  String error = '';

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
      setState(() {
        error = "Please select a valid audio file";
      });
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
        if (error != '')
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 5),
                Container(
                  width: 250,
                  child: Text(
                    "${error}",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
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
  String error = "";

  void addTag() {
    try {
      if (tagsList.contains(tagController.text)) {
        setState(() {
          error = "Tag already exists";
        });
        return;
      }
      if (tagsList.length >= 3) {
        setState(() {
          error = "You can only add 3 tags";
        });
        return;
      }

      setState(() {
        tagsList.add(tagController.text);
        error = "";
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      child: Column(
        children: [
          if (error != "")
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 5),
                  Container(
                    width: 250,
                    child: Text(
                      "${error}",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
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
