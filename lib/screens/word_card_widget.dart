// lib/screens/word_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/word_model.dart';

class WordCardWidget extends StatefulWidget {
  final Word word;
  final String progress;

  const WordCardWidget({super.key, required this.word, required this.progress});

  @override
  State<WordCardWidget> createState() => _WordCardWidgetState();
}

class _WordCardWidgetState extends State<WordCardWidget> {
  bool _isAnswerVisible = false;
  final TextEditingController _textController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  void _setupTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _textController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // İlerleme (örn: 1/50)
                Text(
                  widget.progress,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                SizedBox(height: 30),

                // İngilizce Kelime ve Telaffuz Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.word.en,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up,
                        color: Colors.blueAccent,
                        size: 30,
                      ),
                      onPressed: () => _speak(widget.word.en),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Cevap Yazma Alanı
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    labelText: 'Anlamını yaz...',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),

                // Cevabı Göster/Gizle Butonu
                ElevatedButton(
                  child: Text(
                    _isAnswerVisible ? 'Cevabı Gizle' : 'Cevabı Göster',
                  ),
                  onPressed: () {
                    setState(() {
                      _isAnswerVisible = !_isAnswerVisible;
                    });
                  },
                ),
                SizedBox(height: 30),

                // Cevap Alanı (Sadece _isAnswerVisible true ise görünür)
                if (_isAnswerVisible) _buildAnswerArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Cevabı gösteren alt bölüm
  Widget _buildAnswerArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.word.tr, // Türkçe Anlam
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.green[800]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          if (widget.word.meaning.isNotEmpty &&
              widget.word.meaning != "Tanım bulunamadı.")
            Text(
              "Definition: ${widget.word.meaning}", // İngilizce Anlam
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          SizedBox(height: 10),
          if (widget.word.exampleSentence.isNotEmpty)
            Text(
              "Example: ${widget.word.exampleSentence}", // Örnek Cümle
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}
