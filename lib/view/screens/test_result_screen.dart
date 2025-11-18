import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/models/word_model.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/review_viewmodel.dart';
import '../../viewmodel/settings_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import 'multiple_choice_review_screen.dart';

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
      // Diğer ekranların verilerini tazele
      context.read<HomeViewModel>().loadHomeData();
      context.read<TestMenuViewModel>().loadTestData();
    });
  }

  void _setupTts() async {
    // TTS dilini ayarlardan al
    final targetLang = context.read<SettingsViewModel>().targetLang;
    await flutterTts.setLanguage(targetLang == 'en' ? 'en-US' : targetLang);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) await flutterTts.speak(text);
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
      MaterialPageRoute(builder: (context) => MultipleChoiceReviewScreen()),
    );
  }

  Future<void> _startNewDailyTest() async {
    final viewModel = context.read<ReviewViewModel>();
    await viewModel.startReview('daily');

    if (!mounted) return;

    if (viewModel.reviewQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm günlük kelimeler tamamlandı!')),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MultipleChoiceReviewScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final iconSize = isSmallScreen ? 80.0 : 120.0;
    final titleFontSize = isSmallScreen ? 24.0 : 32.0;
    final bodyFontSize = isSmallScreen ? 16.0 : 20.0;

    // Ayarları al (Dil gösterimi için)
    final settings = context.watch<SettingsViewModel>();

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

            // İstatistik Kartları
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Doğru', '$correct', Colors.green[600]!),
                    _buildStatColumn('Yanlış', '$incorrect', Colors.red[600]!),
                    _buildStatColumn(
                      'Başarı',
                      '%${successRate.toStringAsFixed(0)}',
                      Colors.blue[700]!,
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.3, duration: 500.ms),

            SizedBox(height: 30),

            // Yanlış Kelimeler Listesi
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
                  // Yeni Model Metodlarını Kullanarak Dili Çekiyoruz
                  final targetContent = word.getLocalizedContent(
                    settings.targetLang,
                  );
                  final sourceContent = word.getLocalizedContent(
                    settings.sourceLang,
                  );

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
                        targetContent['word']!, // Hedef Dil (Örn: İngilizce)
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        sourceContent['meaning']!, // Ana Dil (Örn: Türkçe)
                        style: TextStyle(fontSize: bodyFontSize - 2),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.volume_up,
                          color: Colors.blue[700],
                          size: isSmallScreen ? 24 : 32,
                        ),
                        onPressed: () => _speak(targetContent['word']!),
                      ),
                    ),
                  ).animate(delay: (index * 150).ms).fadeIn();
                },
              ),

            SizedBox(height: 40),

            // Butonlar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
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
                icon: Icon(Icons.replay, size: 24),
                label: Text('Yanlışları Tekrar Et'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: dialogColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _repeatWrongWords,
              ).animate().scale(delay: 600.ms),

            SizedBox(height: 12),

            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Yeni Test Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _startNewDailyTest,
            ).animate().scale(delay: 700.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, Color color) {
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
