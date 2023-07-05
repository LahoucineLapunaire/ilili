import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class AddPostPage extends StatelessWidget {
  const AddPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AudioPlayerWidget(
                audioPath:
                    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'),
            Divider(
              height: 50,
              thickness: 2,
            ),
            RecordSection(),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  AudioPlayerWidget({required this.audioPath});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer _audioPlayer = AudioPlayer();
  String _filePath = '';
  bool _isPlaying = false;
  Duration _audioDuration = Duration();
  Duration _position = Duration();

  @override
  void initState() {
    super.initState();
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _audioDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _position = position;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.release();
    super.dispose();
  }

  void _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(_filePath));
      setState(() => _isPlaying = true);
    }
  }

  void _seekToSecond(int second) {
    Duration newDuration = Duration(seconds: second);
    _audioPlayer.seek(newDuration);
  }

  String formatPosition(int position) {
    double result = position / 1000;
    String minutes = (result / 60).floor().toString();
    String secondes = (result % 60).floor().toString();
    return minutes + ':' + secondes;
  }

  Future<void> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        setState(() {
          _filePath = file.path!;
          _audioPlayer.play(UrlSource(_filePath));
        });
      }
    } catch (e) {
      print("Error while picking the file: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _playPause,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(formatPosition(_position.inMilliseconds)),
            SizedBox(width: 5),
            Slider(
              activeColor: Color(0xFF6A1B9A),
              inactiveColor: Color(0xFF6A1B9A).withOpacity(0.3),
              min: 0.0,
              max: _audioDuration.inSeconds.toDouble(),
              value: _position.inSeconds.toDouble(),
              onChanged: (double value) {
                setState(() {
                  _seekToSecond(value.toInt());
                  value = value;
                });
              },
            ),
            SizedBox(width: 5),
            Text(formatPosition(_audioDuration.inMilliseconds)),
          ],
        ),
        ElevatedButton(
            onPressed: () {
              pickAudioFile();
            },
            child: Text('Pick a file')),
      ],
    );
  }
}

class RecordSection extends StatefulWidget {
  const RecordSection({super.key});

  @override
  State<RecordSection> createState() => _RecordSectionState();
}

class _RecordSectionState extends State<RecordSection> {
  FlutterSoundRecorder? audioRecorder;
  FlutterSoundPlayer? _player;
  String? audioFilePath = "";
  late FlutterSound flutterSound;

  void initState() {
    super.initState();
  }

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

      audioRecorder = FlutterSoundRecorder();

      // Start recording audio
      await audioRecorder?.openRecorder();
      await audioRecorder!.startRecorder(toFile: 'path_to_save_recording.aac');
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

        // Play the recorded audio
        _player = FlutterSoundPlayer();

        await _player!.openPlayer();
        await _player!.startPlayer(fromURI: 'path_to_save_recording.aac');
        _player!.setVolume(1.0); // Set volume to maximum (1.0)
      }
    } catch (e) {
      print('Error stopping recording or playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            startRecording();
          },
          child: Text('Start Recording'),
        ),
        ElevatedButton(
          onPressed: () {
            stopRecording();
          },
          child: Text('Stop Recording'),
        )
      ],
    ));
  }
}
