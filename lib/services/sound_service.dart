import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  late AudioPlayer _audioPlayer;

  final String _correctSound = 'audio/ding.mp3';
  final String _incorrectSound = 'audio/buzz.mp3';

  factory SoundService() {
    return _instance;
  }

  SoundService._internal() {
    _audioPlayer = AudioPlayer();
  }

  Future<void> _play(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
      // ignore: empty_catches
    } catch (e) {}
  }

  void playCorrect() {
    _play(_correctSound);
  }

  void playIncorrect() {
    _play(_incorrectSound);
  }
}
