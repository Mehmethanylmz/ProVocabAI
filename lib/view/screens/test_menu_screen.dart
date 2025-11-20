import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import '../../viewmodel/review_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import '../../data/models/test_result.dart';

import 'multiple_choice_review_screen.dart';
import 'listening_review_screen.dart';
import 'speaking_review_screen.dart';

class TestMenuScreen extends StatefulWidget {
  const TestMenuScreen({super.key});

  @override
  State<TestMenuScreen> createState() => _TestMenuScreenState();
}

class _TestMenuScreenState extends State<TestMenuScreen> {
  void _startTest(BuildContext context, String mode, String type) async {
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

      Navigator.push(context, MaterialPageRoute(builder: (_) => page))
          .then((_) {
        if (mounted) menuVM.loadTestData();
      });
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
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
                            ? (vm.dailyReviewCount / vm.dailyTarget)
                                .clamp(0.0, 1.0)
                            : 0,
                        minHeight: 10,
                        backgroundColor: Colors.black.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
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
            ),
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
            _HorizontalFilterRow(
              title: 'filter_category'.tr(),
              items: categories,
              selected: vm.selectedCategories,
              onTap: vm.toggleCategory,
              accentColor: const Color(0xFF7C3AED),
            ),
            _HorizontalFilterRow(
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
                  _BigModeCard(
                    title: 'mode_quiz'.tr(),
                    icon: Icons.format_list_bulleted_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)]),
                    enabled: vm.canStartTest,
                    onTap: () => _startTest(context, 'custom', 'quiz'),
                  ),
                  _BigModeCard(
                    title: 'mode_listening'.tr(),
                    icon: Icons.headphones_rounded,
                    gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
                    enabled: vm.canStartTest,
                    onTap: () => _startTest(context, 'custom', 'listening'),
                  ),
                  _BigModeCard(
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
                child: Text('Son Testler',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937))),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.06, vertical: 8),
                  child: _HistoryCard(result: vm.testHistory[i]),
                ),
                childCount: vm.testHistory.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _HorizontalFilterRow extends StatelessWidget {
  final String title;
  final List<String> items;
  final List<String> selected;
  final Function(String) onTap;
  final Color accentColor;

  const _HorizontalFilterRow({
    required this.title,
    required this.items,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            child: Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569))),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = selected.contains(item);
                return GestureDetector(
                  onTap: () => onTap(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color:
                              isSelected ? accentColor : Colors.grey.shade300,
                          width: 1.5),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        item == 'all' ? 'filter_all'.tr() : item.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: size.height * 0.02),
        ],
      ),
    );
  }
}

class _BigModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final bool enabled;
  final VoidCallback onTap;

  const _BigModeCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(enabled ? 0.15 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ).animate().scale(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TestResult result;

  const _HistoryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rateColor = result.successRate >= 80
        ? Colors.green
        : result.successRate >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: rateColor.withOpacity(0.15),
            child: Text('${result.successRate.toInt()}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rateColor,
                    fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd MMM yyyy - HH:mm').format(result.date),
                    style: GoogleFonts.poppins(
                        fontSize: 15, color: const Color(0xFF475569))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('${result.correct}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 20),
                    Icon(Icons.cancel, size: 20, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${result.wrong}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${result.questions} soru',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: 0.2);
  }
}
