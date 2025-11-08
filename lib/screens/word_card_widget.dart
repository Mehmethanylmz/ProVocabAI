// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\word_card_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_model.dart';
import '../providers/word_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WordCardWidget extends StatefulWidget {
  final Word word;
  final String progress;
  final VoidCallback onKnow;
  final VoidCallback onRepeat;

  const WordCardWidget({
    super.key,
    required this.word,
    required this.progress,
    required this.onKnow,
    required this.onRepeat,
  });

  @override
  State<WordCardWidget> createState() => _WordCardWidgetState();
}

class _WordCardWidgetState extends State<WordCardWidget> {
  bool _isFlipped = false;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setupTts();
    _autoPlaySound();
  }

  void _setupTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _autoPlaySound() {
    final provider = Provider.of<WordProvider>(context, listen: false);
    if (provider.autoPlaySound) {
      _speak(widget.word.en);
    }
  }

  @override
  void didUpdateWidget(covariant WordCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.id != oldWidget.word.id) {
      setState(() {
        _isFlipped = false;
      });
      _autoPlaySound();
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _flipCard() {
    setState(() {
      _isFlipped = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.progress,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: _isFlipped ? null : _flipCard,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  height: 350,
                  padding: const EdgeInsets.all(24.0),
                  child: _isFlipped
                      ? _buildBackContent(theme)
                      : _buildFrontContent(theme),
                ),
              ),
            ),
            if (_isFlipped) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                widget.word.en,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: Icon(Icons.volume_up, color: Colors.blueAccent, size: 30),
              onPressed: () => _speak(widget.word.en),
            ),
          ],
        ),
        SizedBox(height: 20),
        Text(
          'Anlamını tahmin et ve karta dokun',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBackContent(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.word.en,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up, color: Colors.blueAccent, size: 30),
                onPressed: () => _speak(widget.word.en),
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(),
          SizedBox(height: 10),
          Center(
            child: Text(
              widget.word.tr,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          if (widget.word.exampleSentences.isNotEmpty)
            Text(
              'Örnek Cümleler:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          if (widget.word.exampleSentences.isNotEmpty)
            Text(
              widget.word.exampleSentences.join('\n• '),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.left,
            ),
          SizedBox(height: 16),
          if (widget.word.notes.isNotEmpty)
            Text(
              'Notlarım:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          if (widget.word.notes.isNotEmpty)
            Text(
              widget.word.notes,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.left,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onRepeat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Tekrar Göster', style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onKnow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Biliyorum', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
