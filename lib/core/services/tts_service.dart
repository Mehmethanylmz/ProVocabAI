import 'package:flutter_tts/flutter_tts.dart';
import '../init/lang/language_manager.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  final FlutterTts _flutterTts = FlutterTts();

  TtsService._internal() {
    _init();
  }

  void _init() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text, String shortLangCode) async {
    if (text.isEmpty) return;

    String ttsLocale = LanguageManager.instance.getTtsLocale(shortLangCode);

    await _flutterTts.setLanguage(ttsLocale);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
