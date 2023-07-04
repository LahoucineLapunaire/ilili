import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  AudioPlayerWidget({required this.audioPath});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer _audioPlayer = AudioPlayer();
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
      await _audioPlayer.play(UrlSource(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'));
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _playPause,
        ),
        Row(
          children: [
            Text(formatPosition(_position.inMilliseconds)),
            SizedBox(width: 5),
            Slider(
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
              print(_position.inSeconds.toDouble());
            },
            child: Text('Get position'))
      ],
    );
  }
}
