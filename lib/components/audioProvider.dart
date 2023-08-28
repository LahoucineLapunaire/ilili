import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerProvider extends ChangeNotifier {
  AudioPlayer activeAudioPlayers = AudioPlayer();

  void setActiveAudioPlayer(AudioPlayer audioPlayer) {
    if (activeAudioPlayers != audioPlayer) {
      activeAudioPlayers.stop();
      activeAudioPlayers.release();
      activeAudioPlayers = audioPlayer;
    }
    notifyListeners();
  }
}
