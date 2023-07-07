import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

class AudioPlayerWidget extends StatefulWidget {
  final String userId;
  final String postId;

  AudioPlayerWidget({Key? key, required this.userId, required this.postId})
      : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration audioDuration = Duration();
  Duration position = Duration();
  String audioPath = '';
  String profilePicture =
      "https://firebasestorage.googleapis.com/v0/b/ilili-7ebc6.appspot.com/o/users%2Fuser-default.jpg?alt=media&token=8aa7825f-2890-4f63-9fb2-e66e7e916256";
  String username = '';
  String postDate = '';
  List<dynamic> tags = [];
  int likes = 0;
  int comments = 0;

  @override
  void initState() {
    super.initState();
    getUserInfo();
    getPostInfo();
  }

  void getUserInfo() async {
    DocumentSnapshot<Map<String, dynamic>> ds =
        await firestore.collection('users').doc(widget.userId).get();
    setState(() {
      profilePicture = ds.data()!['profilePicture'];
      username = ds.data()!['username'];
    });
    print('profilePicture: $profilePicture');
  }

  void getPostInfo() async {
    DocumentSnapshot<Map<String, dynamic>> ds =
        await firestore.collection('posts').doc(widget.postId).get();
    setState(() {
      audioPath = ds.data()!['audio'];
      tags = ds.data()!['tags'];
      likes = ds.data()!['likes'];
      comments = ds.data()!['comments'];
      postDate = formatTimestamp(ds.data()!['timestamp']);
      audioPlayer.setSourceUrl(audioPath);
      audioPlayer.onDurationChanged.listen((Duration duration) {
        setState(() {
          audioDuration = duration;
        });
        audioPlayer.onPositionChanged.listen((Duration pos) {
          setState(() {
            position = pos;
          });
        });
      });
    });
  }

  Future<void> playPause() async {
    try {
      if (isPlaying) {
        await audioPlayer.pause();
        setState(() => isPlaying = false);
      } else {
        if (audioPath != null) {
          await audioPlayer.play(UrlSource(audioPath)).then((value) {});
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

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();

    String formattedDate = '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.year.toString().substring(2)}';

    String formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';

    return '$formattedDate $formattedTime';
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
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40.0),
              child: Image.network(
                profilePicture, // Replace with the actual path and filename of your image file
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            Text(username),
          ],
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
                  value: position.inSeconds
                      .toDouble()
                      .clamp(0.0, audioDuration.inSeconds.toDouble()),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(children: [
              for (var tag in tags) Text(tag),
              SizedBox(width: 10),
              Text(postDate),
              SizedBox(width: 10),
              Row(
                children: [
                  Text(likes.toString()),
                  IconButton(
                    icon: Icon(Icons.favorite),
                    onPressed: () {
                      setState(() {
                        likes++;
                      });
                    },
                  )
                ],
              ),
              Row(
                children: [
                  Text(comments.toString()),
                  IconButton(
                    icon: Icon(Icons.comment),
                    onPressed: () {
                      setState(() {
                        comments++;
                      });
                    },
                  )
                ],
              )
            ]),
          ],
        )
      ],
    );
  }
}
