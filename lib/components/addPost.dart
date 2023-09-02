import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Ilili/components/google_ads.dart';
import 'package:Ilili/components/widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:Ilili/components/appRouter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'dart:async';
import 'dart:io';

List<String> tagsList = [];
AudioPlayer audioPlayer = AudioPlayer();
String audioPath = '';
UrlSource urlSource = UrlSource('');
Uint8List urlBytes = Uint8List(0);
FirebaseAuth auth = FirebaseAuth.instance;
FirebaseStorage storage = FirebaseStorage.instance;
TextEditingController titleController = TextEditingController();
bool subscription = false;

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  @override
  void dispose() {
    audioPath = '';
    tagsList = [];
    titleController.clear();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      body: SingleChildScrollView(
        child: Center(
            child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.maxFinite,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DelayedDisplay(
                delay: Duration(milliseconds: 500),
                child: HeaderSection(),
              ),
              SizedBox(height: 20),
              DelayedDisplay(
                delay: Duration(milliseconds: 700),
                child: TitleSection(),
              ),
              SizedBox(height: 20),
              DelayedDisplay(
                delay: Duration(milliseconds: 900),
                child: ButtonSection(),
              ),
              SizedBox(height: 30),
              DelayedDisplay(
                delay: Duration(milliseconds: 1100),
                child: AudioPlayerSection(),
              ),
              SizedBox(height: 30),
              Divider(
                height: 30,
                thickness: 2,
              ),
              DelayedDisplay(
                delay: Duration(milliseconds: 1300),
                child: TagsSection(),
              ),
              SizedBox(height: 20),
              DelayedDisplay(
                delay: Duration(milliseconds: 1500),
                child: SendButtonSection(),
              ),
              SizedBox(height: 20),
            ],
          ),
        )),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20),
      width: double.maxFinite,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          "What's new ?",
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Record or upload an audio file, and add some tags to it, and then click on the 'Add Post' button.",
          style: TextStyle(
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        )
      ]),
    );
  }
}

class TitleSection extends StatefulWidget {
  const TitleSection({super.key});

  @override
  State<TitleSection> createState() => _TitleSectionState();
}

class _TitleSectionState extends State<TitleSection> {
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      child: TextField(
        controller: titleController,
        maxLength: 30,
        decoration: InputDecoration(
          filled: true,
          prefixIcon: Icon(Icons.title),
          fillColor: Colors.white,
          labelText: 'title',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
  String pathToAudio = "";

  void startRecording() async {
    try {
      if (audioRecorder != null) {
        // Stop any ongoing recording before starting a new one
        await audioRecorder!.stopRecorder();
      }

      await audioPlayer.stop();
      File existingFile = File('audio.aac');
      if (existingFile.existsSync()) {
        await existingFile.delete();
        print('Existing file deleted');
      }
      if(!(await askPermission())){
        return;
      }
      audioRecorder = FlutterSoundRecorder();

      // Start recording audio
      await audioRecorder?.openRecorder();
      await audioRecorder!.startRecorder(toFile: 'audio.aac');
      setState(() {
        audioPath = '';
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
        String filePath = '/data/user/0/com.example.ilili/cache/audio.aac';
        // Stop the ongoing recording
        await audioRecorder!.stopRecorder().then((value){
          if(value != null){
            filePath = value;
          }
        });
        await audioRecorder!.closeRecorder();
        audioRecorder = null;
        
        setState(() {
          audioPath = filePath;
          isRecording = false;
        });
        if(Platform.isIOS){
          audioPlayer.play(DeviceFileSource(audioPath));
        }
        else{
          audioPlayer.play(UrlSource(audioPath));
        }
      }
    } catch (e) {
      showErrorMessage(e.toString(), context);
      print('Error stopping recording or playing audio: $e');
    }
  }

  UrlSource urlSourceFromBytes(Uint8List bytes,
      {String mimeType = "audio/mpeg"}) {
    return UrlSource(Uri.dataFromBytes(bytes, mimeType: mimeType).toString());
  }

  Future<void> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result != null) {
        PlatformFile file = result.files.first;
        if (kIsWeb) {
          Uint8List bytes = file.bytes!;
          setState(() {
            audioPlayer.setSource(urlSourceFromBytes(bytes));
            urlBytes = bytes;
            urlSource = urlSourceFromBytes(bytes);
          });
        } else {
          setState(() {
            audioPath = file.path!;
            audioPlayer.setSourceUrl(file.path!);
          });
        }
      }
    } catch (e) {
      showErrorMessage(e.toString(), context);
      print("Error while picking the file: ${e.toString()}");
    }
  }

  Future<bool> askPermission() async {
  var microphoneStatus = await Permission.microphone.request();
  if (microphoneStatus != PermissionStatus.granted) {
    print('Microphone Permission not granted');
    return false;
  } else {
    print('Microphone Permission granted');
    return true;
  }
}

  @override
  void dispose() {
    audioRecorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isRecording && !kIsWeb)
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
              fixedSize: Size(175, 40),
              backgroundColor:
                  Color(0xFF6A1B9A), // Set the background color of the button
            ),
          ),
        if (!isRecording && !kIsWeb)
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
              fixedSize: Size(175, 40),
              backgroundColor:
                  Color(0xFF6A1B9A), // Set the background color of the button
            ),
          ),
        SizedBox(width: 5),
        if (!kIsWeb)
          Text(
            "Or",
            style: TextStyle(
              fontFamily: GoogleFonts.poppins().fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        SizedBox(width: 5),
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
            fixedSize: Size(175, 40), // Set the width and height of the button
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
        if (kIsWeb) {
          await audioPlayer.play(urlSource);
        } else {
          await audioPlayer.play(UrlSource(audioPath));
        }

        setState(() => isPlaying = true);
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
        if (audioPath != '' || urlSource.url != '')
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
      tagController.clear();
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
            maxLength: 30,
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
  Reference webStorageRef =
      storage.refFromURL("gs://ilili-7ebc6.appspot.com/posts");
  String audioLink = "";
  InterstitialAd? interstitialAd;

  void initState() {
    super.initState();
    if (!kIsWeb) {
      loadInterstitialAd();
    }
  }

  void loadInterstitialAd() {
    try {
      InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {},
            );

            setState(() {
              interstitialAd = ad;
            });
          },
          onAdFailedToLoad: (err) {
            print('Failed to load an interstitial ad: ${err.message}');
          },
        ),
      );
    } catch (e) {
      print("error interstitial ad : ${e.toString()}");
    }
  }

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

      posts.add(name);
      String title = titleController.text;

      Reference postRef;
      if (kIsWeb) {
        postRef = webStorageRef.child(name);
      } else {
        postRef = storageRef.child(name);
      }
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = postRef.putData(urlBytes);
      } else {
        uploadTask = postRef.putFile(File(audioPath));
      }

      await uploadTask.whenComplete(() async {
        String downloadURL = await postRef.getDownloadURL();

        FirebaseFirestore.instance.collection('posts').doc(name).set({
          'userId': auth.currentUser!.uid,
          "title": title,
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
      showInfoMessage("Your post is posted !", context, () {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppRouter(index: 0),
        ),
      );
    } catch (e) {
      print(e.toString());
    }
  }

  void showConfirmAlert(BuildContext context) {
    if (titleController.text == "" || tagsList.isEmpty) {
      showErrorMessage("please add an audio and fill title and tags", context);
      return;
    }
    if (kIsWeb && urlSource.url == "") {
      showErrorMessage("please add an audio and fill title and tags", context);
      return;
    }
    if (!kIsWeb && audioPath == "") {
      showErrorMessage("please add an audio and fill title and tags", context);
      return;
    }
    // Create a AlertDialog
    AlertDialog alertDialog = AlertDialog(
      title: Text("Do you want to post this audio?"),
      actions: [
        // OK button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
          ),
          child: Text('No', style: TextStyle(color: Colors.black)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6A1B9A),
          ),
          child: Text('Yes', style: TextStyle(color: Colors.white)),
          onPressed: () {
            if (kIsWeb) {
              postAudio();
            } else {
              if (interstitialAd != null) {
                interstitialAd!.show();
              } else {
                print("interstitialAd is null");
              }
              postAudio();
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );

    // Show the alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alertDialog;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showConfirmAlert(context);
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
        fixedSize: Size(250, 50), // Set the width and height of the button
        backgroundColor:
            Color(0xFF6A1B9A), // Set the background color of the button
      ),
    );
  }
}
