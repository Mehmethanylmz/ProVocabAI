import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;

  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;

  SpeechService._internal();

  Future<bool> init() async {
    if (!_isAvailable) {
      try {
        _isAvailable = await _speechToText.initialize(
          onError: (val) => print('Speech Error: $val'),
          onStatus: (val) => print('Speech Status: $val'),
        );
      } catch (e) {
        print("Speech Init Error: $e");
        _isAvailable = false;
      }
    }
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required String localeId,
  }) async {
    if (!_isAvailable) await init();

    if (_isAvailable) {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult || result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenMode: ListenMode.confirmation,
      );
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
