// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\learning_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import '../models/word_model.dart';
import 'word_card_widget.dart';
import 'go_to_review_card.dart';
import 'browse_screen.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  late List<Word> _sessionQueue;
  late int _totalWords;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<WordProvider>(context, listen: false);

    _sessionQueue = List.from(provider.currentBatch);
    _totalWords = _sessionQueue.length;
  }

  void _handleKnow() {
    setState(() {
      _sessionQueue.removeAt(0);
    });
  }

  void _handleRepeat() {
    setState(() {
      final word = _sessionQueue.removeAt(0);
      _sessionQueue.add(word);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Öğrenme Seansı'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              icon: Icon(Icons.list_alt, color: Colors.white),
              label: Text(
                'Listeyi Gör',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BrowseScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _sessionQueue.isEmpty
            ? GoToReviewCard()
            : WordCardWidget(
                key: ValueKey(_sessionQueue.first.id),
                word: _sessionQueue.first,
                progress:
                    '${_totalWords - _sessionQueue.length + 1} / $_totalWords',
                onKnow: _handleKnow,
                onRepeat: _handleRepeat,
              ),
      ),
    );
  }
}
