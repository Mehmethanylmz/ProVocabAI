// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\test_result_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TestResultScreen extends StatefulWidget {
  const TestResultScreen({super.key});

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
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
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WordProvider>(context, listen: false);
    final theme = Theme.of(context);

    final int correct = provider.correctCount;
    final int incorrect = provider.incorrectCount;
    final int total = correct + incorrect;
    final double successRate = (total == 0) ? 0 : (correct / total) * 100;

    String dialogTitle;
    IconData dialogIcon;
    Color dialogColor;

    if (successRate >= 80) {
      dialogTitle = 'Harika İş!';
      dialogIcon = Icons.emoji_events;
      dialogColor = Colors.green;
    } else if (successRate >= 50) {
      dialogTitle = 'İyi Gidiyorsun!';
      dialogIcon = Icons.thumb_up_alt;
      dialogColor = Colors.blue;
    } else {
      dialogTitle = 'Test Bitti';
      dialogIcon = Icons.check_circle_outline;
      dialogColor = Colors.orange;
    }

    final wrongWords = provider.wrongAnswersInSession;

    return Scaffold(
      appBar: AppBar(
        title: Text('Test Sonucu'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(dialogIcon, size: 100, color: dialogColor),
            SizedBox(height: 20),
            Text(
              dialogTitle,
              style: theme.textTheme.displaySmall?.copyWith(
                color: dialogColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Skorun kaydedildi.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      context,
                      'Doğru',
                      correct.toString(),
                      Colors.green,
                    ),
                    _buildStatColumn(
                      context,
                      'Yanlış',
                      incorrect.toString(),
                      Colors.red,
                    ),
                    _buildStatColumn(
                      context,
                      'Başarı',
                      '%${successRate.toStringAsFixed(0)}',
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            if (wrongWords.isNotEmpty)
              Text(
                'Tekrar Gereken Kelimeler',
                style: theme.textTheme.headlineSmall,
              ),
            if (wrongWords.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: wrongWords.length,
                itemBuilder: (context, index) {
                  final word = wrongWords[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        word.en,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(word.tr),
                      trailing: IconButton(
                        icon: Icon(Icons.volume_up, color: Colors.blueAccent),
                        onPressed: () => _speak(word.en),
                      ),
                    ),
                  );
                },
              ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Ana Ekrana Dön', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
