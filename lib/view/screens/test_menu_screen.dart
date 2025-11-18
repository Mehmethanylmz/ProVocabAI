import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// ViewModels
import '../../viewmodel/review_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';

// Widgets
import '../widgets/test/quiz_start_button.dart';
import '../widgets/test/test_history_list.dart';

// Screens (Test Türleri)
import 'multiple_choice_review_screen.dart';
import 'listening_review_screen.dart';
import 'speaking_review_screen.dart';

class TestMenuScreen extends StatefulWidget {
  const TestMenuScreen({super.key});

  @override
  State<TestMenuScreen> createState() => _TestMenuScreenState();
}

class _TestMenuScreenState extends State<TestMenuScreen> {
  /// SRP: View sadece emri verir ve gelen sonuca (Enum) göre navigasyon yapar.
  /// İçerideki 'liste boş mu?' kontrolü ViewModel'in işidir.
  void _startTestProcess(
      BuildContext context, String testMode, String testType) async {
    final reviewViewModel = context.read<ReviewViewModel>();

    // 1. ViewModel'e "Testi Başlat" emrini ver ve sonucu bekle.
    final ReviewStatus status = await reviewViewModel.startReview(testMode);

    if (!mounted) return;

    // 2. Sadece sonuca (Status) göre UI tepkisi ver.
    switch (status) {
      case ReviewStatus.success:
        // Başarılıysa ilgili ekrana git
        _navigateToTestScreen(context, testType);
        break;

      case ReviewStatus.empty:
        // Veri boşsa kullanıcıyı uyar
        _showSnackBar(context, 'Çalışılacak kelime bulunamadı!', isError: true);
        break;

      case ReviewStatus.error:
        // Hata varsa mesaj göster
        _showSnackBar(
            context, reviewViewModel.errorMessage ?? 'Bilinmeyen hata',
            isError: true);
        break;
    }
  }

  void _navigateToTestScreen(BuildContext context, String testType) {
    Widget page;

    switch (testType) {
      case 'listening':
        page = const ListeningReviewScreen();
        break;
      case 'speaking':
        page = const SpeakingReviewScreen();
        break;
      case 'quiz':
      default:
        page = const MultipleChoiceReviewScreen();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      // Testten dönüldüğünde ana menü verilerini tazele
      if (mounted) {
        context.read<TestMenuViewModel>().loadTestData();
      }
    });
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Kullanıcıya test türünü seçtiren alt pencere (Bottom Sheet)
  void _showTestTypeDialog(BuildContext context, String testMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nasıl Çalışmak İstersin?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Öğrenme stilini seç:',
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _buildTestTypeOption(
                context,
                icon: Icons.checklist_rounded,
                title: 'Çoktan Seçmeli',
                subtitle: 'Klasik kart sistemi',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(ctx);
                  _startTestProcess(context, testMode, 'quiz');
                },
              ),
              _buildTestTypeOption(
                context,
                icon: Icons.headphones_rounded,
                title: 'Dinleme Testi',
                subtitle: 'Duyduğunu yaz',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  _startTestProcess(context, testMode, 'listening');
                },
              ),
              _buildTestTypeOption(
                context,
                icon: Icons.mic_rounded,
                title: 'Konuşma Testi',
                subtitle: 'Telaffuzunu geliştir',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(ctx);
                  _startTestProcess(context, testMode, 'speaking');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestTypeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87)),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider'dan verileri dinle
    final viewModel = context.watch<TestMenuViewModel>();

    // Ekran boyutu hesaplamaları
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final padding = isSmallScreen
        ? EdgeInsets.all(size.width * 0.04)
        : const EdgeInsets.all(24.0);
    final appBarHeight = isSmallScreen ? size.height * 0.15 : size.height * 0.2;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Dinamik Başlık Alanı (SliverAppBar)
            SliverAppBar(
              pinned: true,
              expandedHeight: appBarHeight,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Test Alanı',
                  style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10),
                      ]),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF00E676), // Canlı Yeşil
                        Color(0xFF2196F3), // Canlı Mavi
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.quiz_outlined,
                      size: isSmallScreen ? 80 : 120,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),

            // 2. İçerik Alanı
            SliverPadding(
              padding: padding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Yükleniyor Durumu
                  if (viewModel.isLoading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    )),

                  if (!viewModel.isLoading) ...[
                    // Günlük Test Butonu
                    QuizStartButton(
                      title: 'Günlük Test',
                      subtitle:
                          '${viewModel.dailyReviewCount} kelime tekrar için hazır',
                      color: Colors.green[600]!,
                      onTap: () => _showTestTypeDialog(context, 'daily'),
                      isSmallScreen: isSmallScreen,
                    ),

                    const SizedBox(height: 16),

                    // Zor Kelimeler Butonu
                    QuizStartButton(
                      title: 'Zor Kelimeler',
                      subtitle:
                          '${viewModel.difficultWords.length} kelime üzerinde çalış',
                      color: Colors.red[600]!,
                      onTap: () => _showTestTypeDialog(context, 'difficult'),
                      isSmallScreen: isSmallScreen,
                    ),

                    SizedBox(height: size.height * 0.04),

                    // Geçmiş Başlığı
                    Text(
                      'Son Etkinlikler',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212121),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

                    const SizedBox(height: 12),

                    // Geçmiş Listesi
                    TestHistoryList(
                      history: viewModel.testHistory,
                      isSmallScreen: isSmallScreen,
                    ),

                    // Alt boşluk
                    const SizedBox(height: 80),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
