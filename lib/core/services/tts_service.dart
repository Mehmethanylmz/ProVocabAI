import 'package:flutter_tts/flutter_tts.dart';

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

  Future<void> speak(String text, String languageCode) async {
    if (text.isEmpty) return;

    String locale = languageCode;
    if (languageCode == 'en') locale = 'en-US';
    if (languageCode == 'tr') locale = 'tr-TR';
    if (languageCode == 'es') locale = 'es-ES';
    if (languageCode == 'de') locale = 'de-DE';
    if (languageCode == 'fr') locale = 'fr-FR';

    await _flutterTts.setLanguage(locale);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
