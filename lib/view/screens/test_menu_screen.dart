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
import '../../core/extensions/responsive_extension.dart';
import '../../core/constants/app_colors.dart';

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
          content: Text('filter_no_match'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
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
              : 'error_general'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TestMenuViewModel>();

    final categories = ['all', ...vm.allCategories];
    final grammars = ['all', ...vm.allPartsOfSpeech];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Üst boşluk (Status bar çakışmasını önlemek için)
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top),
          ),

          _buildDailyGoalHeader(vm, context),

          SliverToBoxAdapter(
            child: Padding(
              padding: context.responsive.paddingPage.copyWith(bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.science_rounded,
                        color: AppColors.gradientPurple[0],
                        size: context.responsive.iconSizeM,
                      ),
                      SizedBox(width: context.responsive.spacingS),
                      Text(
                        'custom_test_title'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeH2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: context.responsive.spacingM),
          ),

          FilterRow(
            title: 'filter_category'.tr(),
            items: categories,
            selected: vm.selectedCategories,
            onTap: vm.toggleCategory,
            accentColor: AppColors.gradientPurple[0],
          ),

          FilterRow(
            title: 'filter_grammar'.tr(),
            items: grammars,
            selected: vm.selectedGrammar,
            onTap: vm.toggleGrammar,
            accentColor: AppColors.gradientPink[0],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(vertical: context.responsive.spacingL),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '${vm.filteredWordCount} ${'lab_match_count'.tr()}',
                    key: ValueKey(vm.filteredWordCount),
                    style: GoogleFonts.poppins(
                      fontSize: context.responsive.fontSizeH3,
                      fontWeight: FontWeight.bold,
                      color:
                          vm.canStartTest ? AppColors.success : AppColors.error,
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
                crossAxisCount: context.responsive.value(
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                ),
                childAspectRatio: context.responsive.value(
                  mobile: 3.8,
                  tablet: 2.0,
                  desktop: 1.7,
                ),
                mainAxisSpacing: context.responsive.spacingM,
                crossAxisSpacing: context.responsive.spacingL,
              ),
              delegate: SliverChildListDelegate.fixed([
                ModeCard(
                  title: 'mode_quiz'.tr(),
                  icon: Icons.format_list_bulleted_rounded,
                  gradient: LinearGradient(colors: AppColors.gradientPurple),
                  enabled: vm.canStartTest,
                  onTap: () => _startTest(context, 'custom', 'quiz'),
                ),
                ModeCard(
                  title: 'mode_listening'.tr(),
                  icon: Icons.headphones_rounded,
                  gradient: LinearGradient(colors: AppColors.gradientPink),
                  enabled: vm.canStartTest,
                  onTap: () => _startTest(context, 'custom', 'listening'),
                ),
                ModeCard(
                  title: 'mode_speaking'.tr(),
                  icon: Icons.mic_rounded,
                  gradient: LinearGradient(colors: AppColors.gradientGreen),
                  enabled: vm.canStartTest,
                  onTap: () => _startTest(context, 'custom', 'speaking'),
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: context.responsive.spacingXL),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: context.responsive.paddingPage.copyWith(top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'test_history_title'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: context.responsive.fontSizeH2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: context.responsive.spacingXS),
                  Text(
                    'test_history_desc'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: context.responsive.fontSizeCaption,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: context.responsive.spacingM),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.value(
                    mobile: 20,
                    tablet: 24,
                    desktop: 32,
                  ),
                  vertical: context.responsive.spacingS,
                ),
                child: HistoryCardWidget(result: vm.testHistory[i]),
              ),
              childCount: vm.testHistory.length,
            ),
          ),

          // BottomNavigationBar'ın üzerine binmemesi için ekstra boşluk
          SliverToBoxAdapter(
            child: SizedBox(
                height: context.responsive.bottomNavHeight +
                    context.responsive.spacingXL),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalHeader(TestMenuViewModel vm, BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: context.responsive.paddingPage,
        padding: EdgeInsets.all(context.responsive.spacingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(context.responsive.borderRadiusXL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
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
                        color: AppColors.surface.withOpacity(0.9),
                        fontSize: context.responsive.fontSizeBody,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: context.responsive.spacingXS),
                    Text(
                      "${vm.dailyReviewCount}/${vm.dailyTarget}",
                      style: GoogleFonts.poppins(
                        color: AppColors.surface,
                        fontSize: context.responsive.fontSizeH1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(context.responsive.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: AppColors.surface,
                    size: context.responsive.iconSizeL,
                  ),
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
                minHeight: context.responsive.value(
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
                backgroundColor: Colors.black.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(AppColors.success),
              ),
            ),
            SizedBox(height: context.responsive.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startTest(context, 'daily', 'quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(context.responsive.borderRadiusL),
                  ),
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
