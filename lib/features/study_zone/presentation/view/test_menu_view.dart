import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';

import '../widgets/filter_row.dart';
import '../widgets/history_card_widget.dart';
import '../widgets/mode_card.dart';

class TestMenuView extends StatelessWidget {
  const TestMenuView({super.key});

  Future<void> _startTest(BuildContext context, String mode, String type,
      MenuViewModel menuVM, StudyViewModel studyVM) async {
    if (mode == 'custom' && !menuVM.canStartTest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('filter_no_match'.tr()),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
          child: CircularProgressIndicator(color: context.colors.primary)),
    );

    await studyVM.startReview(
      mode,
      categoryFilter: menuVM.selectedCategories,
    );

    if (!context.mounted) return;
    Navigator.pop(context);

    if (studyVM.status == StudyStatus.success) {
      Widget page;
      switch (type) {
        case 'listening':
          page = const ListeningView();
          break;
        case 'speaking':
          page = const SpeakingView();
          break;
        default:
          page = const QuizView();
      }

      await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      menuVM.loadMenuData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(studyVM.status == StudyStatus.empty
              ? 'filter_no_match'.tr()
              : 'error_general'.tr()),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<MenuViewModel>(
      viewModel: locator<MenuViewModel>(),
      onModelReady: (model) => model.loadMenuData(),
      builder: (context, vm, child) {
        final studyVM = context.read<StudyViewModel>();
        final categories = ['all', ...vm.allCategories];

        return Scaffold(
          backgroundColor: context.colors.surface,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.top)),
              _buildDailyGoalHeader(context, vm),
              SliverToBoxAdapter(
                child: Padding(
                  padding: context.responsive.paddingPage.copyWith(bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.science_rounded,
                              color: context.ext.gradientPurple[0],
                              size: context.responsive.iconSizeM),
                          SizedBox(width: context.responsive.spacingS),
                          Text(
                            'custom_test_title'.tr(),
                            style: context.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(height: context.responsive.spacingM)),
              FilterRow(
                title: 'filter_category'.tr(),
                items: categories,
                selected: vm.selectedCategories,
                onTap: vm.toggleCategory,
                accentColor: context.ext.gradientPurple[0],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: context.responsive.spacingL),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '${vm.filteredWordCount} ${'lab_match_count'.tr()}',
                        key: ValueKey(vm.filteredWordCount),
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeH3,
                          fontWeight: FontWeight.bold,
                          color: vm.canStartTest
                              ? context.ext.success
                              : context.colors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: context.responsive.paddingPage.copyWith(top: 0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.responsive
                        .value(mobile: 1, tablet: 2, desktop: 3),
                    childAspectRatio: context.responsive
                        .value(mobile: 3.8, tablet: 2.0, desktop: 1.7),
                    mainAxisSpacing: context.responsive.spacingM,
                    crossAxisSpacing: context.responsive.spacingL,
                  ),
                  delegate: SliverChildListDelegate.fixed([
                    ModeCard(
                      title: 'mode_quiz'.tr(),
                      icon: Icons.format_list_bulleted_rounded,
                      gradient: context.ext.gradientPurple,
                      enabled: vm.canStartTest,
                      onTap: () =>
                          _startTest(context, 'custom', 'quiz', vm, studyVM),
                    ),
                    ModeCard(
                      title: 'mode_listening'.tr(),
                      icon: Icons.headphones_rounded,
                      gradient: [
                        context.colors.error,
                        context.colors.error.withOpacity(0.7)
                      ],
                      enabled: vm.canStartTest,
                      onTap: () => _startTest(
                          context, 'custom', 'listening', vm, studyVM),
                    ),
                    ModeCard(
                      title: 'mode_speaking'.tr(),
                      icon: Icons.mic_rounded,
                      gradient: [
                        context.ext.success,
                        context.ext.success.withOpacity(0.7)
                      ],
                      enabled: vm.canStartTest,
                      onTap: () => _startTest(
                          context, 'custom', 'speaking', vm, studyVM),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(height: context.responsive.spacingXL)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: context.responsive.paddingPage.copyWith(top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'test_history_title'.tr(),
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                      SizedBox(height: context.responsive.spacingXS),
                      Text(
                        'test_history_desc'.tr(),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(height: context.responsive.spacingM)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive
                          .value(mobile: 20, tablet: 24, desktop: 32),
                      vertical: context.responsive.spacingS,
                    ),
                    child: HistoryCard(result: vm.testHistory[i]),
                  ),
                  childCount: vm.testHistory.length,
                ),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(
                      height: context.responsive.bottomNavHeight +
                          context.responsive.spacingXL)),
            ],
          ),
        );
      },
    );
  }

  // ── Premium Günlük Hedef Kartı ──────────────────────────────────────────
  Widget _buildDailyGoalHeader(BuildContext context, MenuViewModel vm) {
    final bool isCompleted = vm.isDailyGoalCompleted;
    final double progress = vm.dailyTarget > 0
        ? (vm.dailyReviewCount / vm.dailyTarget).clamp(0.0, 1.0)
        : 0.0;
    final int remaining =
        (vm.dailyTarget - vm.dailyReviewCount).clamp(0, vm.dailyTarget);

    final Color accentColor =
        isCompleted ? const Color(0xFFFFC107) : const Color(0xFF6C63FF);
    final Color barColor =
        isCompleted ? const Color(0xFFFFC107) : const Color(0xFF00E5A0);

    return SliverToBoxAdapter(
      child: Container(
        margin: context.responsive.paddingPage,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted
                ? [const Color(0xFF2C1A00), const Color(0xFF4A2E00)]
                : [const Color(0xFF0D0B22), const Color(0xFF171642)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(context.responsive.borderRadiusXL),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.25),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Satır 1: ikon+etiket  |  rozet ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.emoji_events_rounded
                              : Icons.bolt_rounded,
                          color: accentColor,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Günlük Hedef',
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  // Rozet
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accentColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      isCompleted ? '✓ TAMAMLANDI' : '$remaining kelime kaldı',
                      style: GoogleFonts.poppins(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Satır 2: büyük sayaç  |  yüzde ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${vm.dailyReviewCount}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7, left: 5),
                    child: Text(
                      '/ ${vm.dailyTarget}',
                      style: GoogleFonts.poppins(
                        color: Colors.white30,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      color: barColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── İnce gradient progress bar ──
              Stack(
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (ctx, constraints) => AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      height: 5,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCompleted
                              ? [
                                  const Color(0xFFFF9800),
                                  const Color(0xFFFFC107)
                                ]
                              : [
                                  const Color(0xFF00C9A7),
                                  const Color(0xFF00E5A0)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                              color: barColor.withOpacity(0.55), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Alt açıklama ──
              Text(
                isCompleted
                    ? '🎉 Harika! Bugünkü hedefinizi tamamladınız.'
                    : 'Herhangi bir testten kelime çözerek ilerleyin',
                style: GoogleFonts.poppins(
                  color: Colors.white30,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 350.ms)
          .slideY(begin: -0.08, duration: 350.ms),
    );
  }
}
