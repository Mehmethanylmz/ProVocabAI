import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/review_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import 'review_screen_multiple_choice.dart';
import '../widgets/test/quiz_start_button.dart';
import '../widgets/test/test_history_list.dart';

class TestMenuScreen extends StatefulWidget {
  const TestMenuScreen({super.key});

  @override
  State<TestMenuScreen> createState() => _TestMenuScreenState();
}

class _TestMenuScreenState extends State<TestMenuScreen> {
  void _startTest(BuildContext context, String testMode) async {
    final reviewViewModel = context.read<ReviewViewModel>();
    await reviewViewModel.startReview(testMode);

    if (!mounted) return;

    if (reviewViewModel.reviewQueue.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hazır kelime yok!')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewScreenMultipleChoice()),
    ).then((_) {
      // Testten geri dönüldüğünde Test Geçmişini yenile
      context.read<TestMenuViewModel>().fetchTestHistory();
      // Home ekranındaki verileri de (dolaylı olarak) yenilemek gerekebilir
      // ama şimdilik sadece burayı yeniliyoruz.
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TestMenuViewModel>();
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final padding = isSmallScreen
        ? EdgeInsets.all(size.width * 0.04)
        : EdgeInsets.all(24.0);
    final appBarHeight = isSmallScreen ? size.height * 0.15 : size.height * 0.2;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
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
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00E676), Color(0xFF2196F3)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.quiz,
                      size: isSmallScreen ? 60 : 100,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: padding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  QuizStartButton(
                    title: 'Günlük Testi Başlat',
                    subtitle: '${viewModel.dailyReviewCount} kelime hazır',
                    color: Colors.green[600]!,
                    onTap: () => _startTest(context, 'daily'),
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: 16),
                  QuizStartButton(
                    title: 'Zor Kelimeleri Tekrar Et',
                    subtitle: '${viewModel.difficultWords.length} kelime',
                    color: Colors.red[600]!,
                    onTap: () => _startTest(context, 'difficult'),
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: size.height * 0.03),
                  Text(
                    'Test Geçmişi (Son 3 Gün)',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 22 : 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ).animate().fadeIn(duration: 600.ms),
                  SizedBox(height: 8),
                  TestHistoryList(
                    history: viewModel.testHistory,
                    isSmallScreen: isSmallScreen,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
