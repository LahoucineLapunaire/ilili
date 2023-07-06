import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  AudioPlayerWidget({required this.audioPath, Key? key}) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration audioDuration = Duration();
  Duration position = Duration();

  @override
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

  Future<void> playPause() async {
    try {
      if (isPlaying) {
        await audioPlayer.pause();
        setState(() => isPlaying = false);
      } else {
        if (widget.audioPath != null) {
          await audioPlayer.play(UrlSource(widget.audioPath));
          setState(() => isPlaying = true);
        }
      }
    } catch (e) {
      setState(() {
        print('Error: $e');
      });
    }
  }

  void _seekToSecond(int second) {
    Duration newDuration = Duration(seconds: second);
    audioPlayer.seek(newDuration);
  }

  String formatPosition(int position) {
    double result = position / 1000;
    String minutes = (result / 60).floor().toString().padLeft(2, '0');
    String seconds = (result % 60).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    audioPlayer.release();
    audioPlayer.dispose();
    super.dispose();
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
                    });
                  },
                ),
                Text(formatPosition(audioDuration.inMilliseconds)),
              ],
            )
          ],
        ),
      ],
    );
  }
}
