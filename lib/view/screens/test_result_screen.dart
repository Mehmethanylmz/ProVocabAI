import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/word_model.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/review_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import 'review_screen_multiple_choice.dart';

class TestResultScreen extends StatefulWidget {
  final int correctCount;
  final int incorrectCount;
  final List<Word> wrongWords;

  const TestResultScreen({
    super.key,
    required this.correctCount,
    required this.incorrectCount,
    required this.wrongWords,
  });

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _setupTts();
    _saveResultAndRefreshData();
  }

  void _saveResultAndRefreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reviewVM = context.read<ReviewViewModel>();
      await reviewVM.saveTestResult();

      if (!mounted) return;
      context.read<HomeViewModel>().loadHomeData();
      context.read<TestMenuViewModel>().loadTestData();
    });
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

  Future<void> _repeatWrongWords() async {
    final viewModel = context.read<ReviewViewModel>();
    await viewModel.startReviewWithWords(widget.wrongWords);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ReviewScreenMultipleChoice()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final iconSize = isSmallScreen ? 80.0 : 120.0;
    final titleFontSize = isSmallScreen ? 24.0 : 32.0;
    final bodyFontSize = isSmallScreen ? 16.0 : 20.0;

    final int correct = widget.correctCount;
    final int incorrect = widget.incorrectCount;
    final int total = correct + incorrect;
    final double successRate = (total == 0) ? 0 : (correct / total) * 100;

    String dialogTitle;
    IconData dialogIcon;
    Color dialogColor;

    if (successRate >= 80) {
      dialogTitle = 'Harika İş!';
      dialogIcon = Icons.emoji_events;
      dialogColor = Colors.green[600]!;
    } else if (successRate >= 50) {
      dialogTitle = 'İyi Gidiyorsun!';
      dialogIcon = Icons.thumb_up_alt;
      dialogColor = Colors.blue[700]!;
    } else {
      dialogTitle = 'Test Bitti';
      dialogIcon = Icons.check_circle_outline;
      dialogColor = Colors.orange[600]!;
    }

    final wrongWords = widget.wrongWords;

    return Scaffold(
      appBar: AppBar(
        title: Text('Test Sonucu', style: TextStyle(fontSize: titleFontSize)),
        automaticallyImplyLeading: false,
        backgroundColor: dialogColor.withOpacity(0.8),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              dialogIcon,
              size: iconSize,
              color: dialogColor,
            ).animate().scale(duration: 600.ms, curve: Curves.bounceOut),
            SizedBox(height: 20),
            Text(
              dialogTitle,
              style: TextStyle(
                fontSize: titleFontSize,
                color: dialogColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            SizedBox(height: 10),
            Text(
              'Skorun kaydedildi.',
              style: TextStyle(fontSize: bodyFontSize),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            SizedBox(height: 30),
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: isSmallScreen
                    ? Column(
                        children: [
                          _buildStatColumn(
                            context,
                            'Doğru',
                            correct.toString(),
                            Colors.green[600]!,
                          ),
                          SizedBox(height: 16),
                          _buildStatColumn(
                            context,
                            'Yanlış',
                            incorrect.toString(),
                            Colors.red[600]!,
                          ),
                          SizedBox(height: 16),
                          _buildStatColumn(
                            context,
                            'Başarı',
                            '%${successRate.toStringAsFixed(0)}',
                            Colors.blue[700]!,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            context,
                            'Doğru',
                            correct.toString(),
                            Colors.green[600]!,
                          ),
                          _buildStatColumn(
                            context,
                            'Yanlış',
                            incorrect.toString(),
                            Colors.red[600]!,
                          ),
                          _buildStatColumn(
                            context,
                            'Başarı',
                            '%${successRate.toStringAsFixed(0)}',
                            Colors.blue[700]!,
                          ),
                        ],
                      ),
              ),
            ).animate().slideY(begin: 0.3, duration: 500.ms),
            SizedBox(height: 30),
            if (wrongWords.isNotEmpty)
              Text(
                'Tekrar Gereken Kelimeler',
                style: TextStyle(
                  fontSize: titleFontSize - 4,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 400.ms),
            if (wrongWords.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: wrongWords.length,
                itemBuilder: (context, index) {
                  final word = wrongWords[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      title: Text(
                        word.en,
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        word.tr,
                        style: TextStyle(fontSize: bodyFontSize - 2),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.volume_up,
                          color: Colors.blue[700],
                          size: isSmallScreen ? 24 : 32,
                        ),
                        onPressed: () => _speak(word.en),
                      ),
                    ),
                  ).animate(delay: (index * 150).ms).fadeIn();
                },
              ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Ana Ekrana Dön',
                style: TextStyle(fontSize: bodyFontSize),
              ),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ).animate().scale(delay: 500.ms),
            SizedBox(height: 12),
            if (wrongWords.isNotEmpty)
              OutlinedButton.icon(
                icon: Icon(Icons.replay, size: isSmallScreen ? 24 : 32),
                label: Text(
                  'Yanlışları Tekrar Et (${wrongWords.length} kelime)',
                  style: TextStyle(fontSize: bodyFontSize - 2),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  side: BorderSide(color: dialogColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _repeatWrongWords,
              ).animate().scale(delay: 600.ms),
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
          style: TextStyle(
            fontSize: 28,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 18)),
      ],
    );
  }
}
