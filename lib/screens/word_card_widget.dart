import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/word_model.dart';
import 'dart:async';

class WordCardWidget extends StatefulWidget {
  final Word word;
  final String progress;

  const WordCardWidget({super.key, required this.word, required this.progress});

  @override
  State<WordCardWidget> createState() => _WordCardWidgetState();
}

class _WordCardWidgetState extends State<WordCardWidget> {
  bool _isAnswerVisible = false;
  bool _isHintVisible = false;

  final FlutterTts flutterTts = FlutterTts();
  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  @override
  void didUpdateWidget(covariant WordCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.id != oldWidget.word.id) {
      setState(() {
        _isAnswerVisible = false;
        _isHintVisible = false;
      });
    }
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
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.progress,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                SizedBox(height: 30),
                _buildWordHeader(),
                SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: _isAnswerVisible
                      ? _buildAnswerArea()
                      : _buildQuestionArea(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            widget.word.en,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: Icon(Icons.volume_up, color: Colors.blueAccent, size: 30),
          onPressed: () => _speak(widget.word.en),
        ),
      ],
    );
  }

  Widget _buildQuestionArea() {
    return Column(
      key: ValueKey('question'),
      children: [
        TextButton.icon(
          icon: Icon(
            _isHintVisible ? Icons.lightbulb : Icons.lightbulb_outline,
          ),
          label: Text(_isHintVisible ? 'İpucunu Gizle' : 'İpucu İste'),
          onPressed: () {
            setState(() {
              _isHintVisible = !_isHintVisible;
            });
          },
        ),
        SizedBox(height: 10),

        if (_isHintVisible) _buildHintBox(),

        SizedBox(height: 30),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text('Cevabı Göster'),
          onPressed: () {
            setState(() {
              _isAnswerVisible = true;
              _isHintVisible = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAnswerArea() {
    if (widget.word.tr.isEmpty && widget.word.meaning.isEmpty) {
      return Text("Bu kelime için detay bulunamadı.");
    }

    return Container(
      key: ValueKey('answer'),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.word.tr,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.green[800],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 25),

          if (widget.word.meaning.isNotEmpty &&
              widget.word.meaning != "Tanım bulunamadı.")
            _buildInfoRow(Icons.info_outline, "Tanım:", widget.word.meaning),

          if (widget.word.exampleSentence.isNotEmpty)
            _buildInfoRow(
              Icons.format_quote,
              "Örnek:",
              widget.word.exampleSentence,
            ),

          SizedBox(height: 30),

          TextButton(
            child: Text('Kartı Çevir'),
            onPressed: () {
              setState(() {
                _isAnswerVisible = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHintBox() {
    String hintText = widget.word.exampleSentence.isNotEmpty
        ? widget.word.exampleSentence
        : (widget.word.meaning.isNotEmpty &&
                  widget.word.meaning != "Tanım bulunamadı."
              ? widget.word.meaning
              : "Bu kelime için ipucu bulunamadı.");

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, size: 18, color: Colors.blue[700]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              hintText,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
