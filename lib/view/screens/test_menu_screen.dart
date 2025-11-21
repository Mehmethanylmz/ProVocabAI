import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../viewmodel/review_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';

import '../widgets/test/filter_row.dart';
import '../widgets/test/mode_card.dart';
import '../widgets/test/history_card_widget.dart';

import 'multiple_choice_review_screen.dart';
import 'listening_review_screen.dart';
import 'speaking_review_screen.dart';

class TestMenuScreen extends StatefulWidget {
  const TestMenuScreen({super.key});

  @override
  State<TestMenuScreen> createState() => _TestMenuScreenState();
}

class _TestMenuScreenState extends State<TestMenuScreen> {
  Future<void> _startTest(
      BuildContext context, String mode, String type) async {
    final menuVM = context.read<TestMenuViewModel>();
    final reviewVM = context.read<ReviewViewModel>();

    if (mode == 'custom' && !menuVM.canStartTest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('filter_no_match'.tr()), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final status = await reviewVM.startReview(
      mode,
      categoryFilter: menuVM.selectedCategories,
      grammarFilter: menuVM.selectedGrammar,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (status == ReviewStatus.success) {
      Widget page;
      switch (type) {
        case 'listening':
          page = const ListeningReviewScreen();
          break;
        case 'speaking':
          page = const SpeakingReviewScreen();
          break;
        default:
          page = const MultipleChoiceReviewScreen();
      }

      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));

      if (mounted) {
        menuVM.loadTestData();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(status == ReviewStatus.empty
                ? 'filter_no_match'.tr()
                : 'Error'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TestMenuViewModel>();
    final size = MediaQuery.of(context).size;

    final categories = ['all', ...vm.allCategories];
    final grammars = ['all', ...vm.allPartsOfSpeech];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      // DÜZELTME 1: SafeArea kaldırıldı, doğrudan CustomScrollView kullanılıyor.
      // Böylece içerik ekranın en altına kadar uzanabilecek.
      body: CustomScrollView(
        slivers: [
          // Üst boşluk (Status bar çakışmasını önlemek için)
          SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top)),

          _buildDailyGoalHeader(vm, context),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science_rounded, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Text(
                        'custom_test_title'.tr(),
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          FilterRow(
            title: 'filter_category'.tr(),
            items: categories,
            selected: vm.selectedCategories,
            onTap: vm.toggleCategory,
            accentColor: const Color(0xFF7C3AED),
          ),

          FilterRow(
            title: 'filter_grammar'.tr(),
            items: grammars,
            selected: vm.selectedGrammar,
            onTap: vm.toggleGrammar,
            accentColor: const Color(0xFFEC4899),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '${vm.filteredWordCount} ${'lab_match_count'.tr()}',
                    key: ValueKey(vm.filteredWordCount),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: vm.canStartTest
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size.width > 600 ? 3 : 1,
                childAspectRatio: size.width > 600 ? 1.7 : 3.8,
                mainAxisSpacing: 16,
                crossAxisSpacing: 20,
              ),
              delegate: SliverChildListDelegate.fixed([
                ModeCard(
                  title: 'mode_quiz'.tr(),
                  icon: Icons.format_list_bulleted_rounded,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                  enabled: vm.canStartTest,
                  onTap: () => _startTest(context, 'custom', 'quiz'),
                ),
                ModeCard(
                  title: 'mode_listening'.tr(),
                  icon: Icons.headphones_rounded,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
                  enabled: vm.canStartTest,
                  onTap: () => _startTest(context, 'custom', 'listening'),
                ),
                ModeCard(
                  title: 'mode_speaking'.tr(),
                  icon: Icons.mic_rounded,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]),
                  enabled: vm.canStartTest,
                  onTap: () => _startTest(context, 'custom', 'speaking'),
                ),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Son Testler',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937))),
                  const SizedBox(height: 4),
                  Text(
                    'Burada sadece son 3 günün testleri görünür. Daha eskiler için "İlerleme" ekranına bakın.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06, vertical: 8),
                child: HistoryCardWidget(result: vm.testHistory[i]),
              ),
              childCount: vm.testHistory.length,
            ),
          ),
          // DÜZELTME 2: BottomNavigationBar'ın üzerine binmemesi için ekstra boşluk
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildDailyGoalHeader(TestMenuViewModel vm, BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'daily_test'.tr(),
                      style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${vm.dailyReviewCount}/${vm.dailyTarget}",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_rounded,
                      color: Colors.white, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: vm.dailyTarget > 0
                    ? (vm.dailyReviewCount / vm.dailyTarget).clamp(0.0, 1.0)
                    : 0,
                minHeight: 10,
                backgroundColor: Colors.black.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startTest(context, 'daily', 'quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D4ED8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'btn_start'.tr().toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: -0.2, duration: 500.ms),
    );
  }
}
