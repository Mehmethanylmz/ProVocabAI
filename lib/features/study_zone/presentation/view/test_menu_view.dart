import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../view_model/menu_view_model.dart';
import '../view_model/study_view_model.dart';
import '../widgets/filter_row.dart';
import '../widgets/history_card_widget.dart';
import '../widgets/mode_card.dart';

import 'quiz_view.dart';
import 'listening_view.dart';
import 'speaking_view.dart';

class TestMenuView extends StatelessWidget {
  const TestMenuView({super.key});

  Future<void> _startTest(
      BuildContext context, String mode, String type) async {
    final menuVM = locator<MenuViewModel>();
    final studyVM = locator<StudyViewModel>();

    if (mode == 'custom' && !menuVM.canStartTest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('filter_no_match'.tr()),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    // Yükleniyor dialogu
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
          child: CircularProgressIndicator(color: context.colors.primary)),
    );

    await studyVM.startReview(
      mode,
      categoryFilter: menuVM.selectedCategories,
      grammarFilter: menuVM.selectedGrammar,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // Dialog kapat

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
      onModelReady: (model) => model.loadMenuData(), // onModelReady kullanıldı
      builder: (context, vm, child) {
        final categories = ['all', ...vm.allCategories];
        final grammars = ['all', ...vm.allPartsOfSpeech];

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
              FilterRow(
                title: 'filter_grammar'.tr(),
                items: grammars,
                selected: vm.selectedGrammar,
                onTap: vm.toggleGrammar,
                accentColor: context.ext.gradientBlue[0],
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
                      onTap: () => _startTest(context, 'custom', 'quiz'),
                    ),
                    ModeCard(
                      title: 'mode_listening'.tr(),
                      icon: Icons.headphones_rounded,
                      gradient: [
                        context.colors.error,
                        context.colors.error.withOpacity(0.7)
                      ],
                      enabled: vm.canStartTest,
                      onTap: () => _startTest(context, 'custom', 'listening'),
                    ),
                    ModeCard(
                      title: 'mode_speaking'.tr(),
                      icon: Icons.mic_rounded,
                      gradient: [
                        context.ext.success,
                        context.ext.success.withOpacity(0.7)
                      ],
                      enabled: vm.canStartTest,
                      onTap: () => _startTest(context, 'custom', 'speaking'),
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

  Widget _buildDailyGoalHeader(BuildContext context, MenuViewModel vm) {
    return SliverToBoxAdapter(
      child: Container(
        margin: context.responsive.paddingPage,
        padding: EdgeInsets.all(context.responsive.spacingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.primary, context.colors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(context.responsive.borderRadiusXL),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withOpacity(0.4),
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
                        color: context.colors.onPrimary.withOpacity(0.9),
                        fontSize: context.responsive.fontSizeBody,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: context.responsive.spacingXS),
                    Text(
                      "${vm.dailyReviewCount}/${vm.dailyTarget}",
                      style: GoogleFonts.poppins(
                        color: context.colors.onPrimary,
                        fontSize: context.responsive.fontSizeH1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(context.responsive.spacingM),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.flag_rounded,
                      color: context.colors.onPrimary,
                      size: context.responsive.iconSizeL),
                ),
              ],
            ),
            SizedBox(height: context.responsive.spacingL),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(context.responsive.borderRadiusM),
              child: LinearProgressIndicator(
                value: vm.dailyTarget > 0
                    ? (vm.dailyReviewCount / vm.dailyTarget).clamp(0.0, 1.0)
                    : 0,
                minHeight: context.responsive
                    .value(mobile: 8, tablet: 10, desktop: 12),
                backgroundColor: Colors.black.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(context.ext.success),
              ),
            ),
            SizedBox(height: context.responsive.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startTest(context, 'daily', 'quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.surface,
                  foregroundColor: context.colors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusL)),
                  padding: EdgeInsets.symmetric(
                      vertical: context.responsive.spacingM),
                ),
                child: Text(
                  'btn_start'.tr().toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: context.responsive.fontSizeBody,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: -0.2, duration: 500.ms),
    );
  }
}
