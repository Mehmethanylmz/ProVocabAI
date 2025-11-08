// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\browse_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/word_model.dart';
import '../providers/word_provider.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final FlutterTts flutterTts = FlutterTts();
  int? _expandedWordId;

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
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Word> words = Provider.of<WordProvider>(
      context,
      listen: false,
    ).currentBatch;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Seansa Göz At (${words.length} Kelime)')),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        itemCount: words.length,
        itemBuilder: (context, index) {
          final word = words[index];
          final isExpanded = _expandedWordId == word.id;

          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 20.0,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.en,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.volume_up, color: Colors.blueAccent),
                        onPressed: () => _speak(word.en),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    word.tr,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() {
                      _expandedWordId = isExpanded ? null : word.id;
                    });
                  },
                ),
                AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    height: isExpanded ? null : 0,
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      top: 10,
                    ),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 1),
                        SizedBox(height: 12),
                        Text(
                          'Örnek Cümleler:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        word.exampleSentences.isEmpty
                            ? Text(
                                'Örnek cümle bulunamadı.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              )
                            : Text(
                                '• ${word.exampleSentences.join('\n• ')}',
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.left,
                              ),
                        SizedBox(height: 16),
                        Text(
                          'Notlarım:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        word.notes.isEmpty
                            ? Text(
                                'Kişisel not bulunamadı.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              )
                            : Text(
                                word.notes,
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.left,
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
