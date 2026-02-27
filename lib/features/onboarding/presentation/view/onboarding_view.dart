// lib/features/onboarding/presentation/view/onboarding_view.dart
//
// REWRITE: context.watch<OnboardingViewModel>() → BlocBuilder<OnboardingBloc>
// DI: OnboardingBloc → NavigationRoute'ta BlocProvider ile sağlanır

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/lang/language_manager.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../state/onboarding_bloc.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (prev, curr) =>
          curr.isCompleted != prev.isCompleted ||
          curr.errorMessage != prev.errorMessage,
      listener: (context, state) {
        if (state.isCompleted) {
          NavigationService.instance
              .navigateToPageClear(path: NavigationConstants.LOGIN);
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.colors.surface,
            body: SafeArea(
              child: Padding(
                padding: context.responsive.paddingPage,
                child: Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: state.currentPage,
                        children: [
                          _buildLanguageSelection(
                            context,
                            state: state,
                            title: 'onboard_lang_source_title'.tr(),
                            subtitle: 'onboard_lang_source_desc'.tr(),
                            selectedValue: state.sourceLang,
                            onSelect: (code) => context
                                .read<OnboardingBloc>()
                                .add(OnboardingSourceLangChanged(code)),
                          ),
                          _buildLanguageSelection(
                            context,
                            state: state,
                            title: 'onboard_lang_target_title'.tr(),
                            subtitle: 'onboard_lang_target_desc'.tr(),
                            selectedValue: state.targetLang,
                            onSelect: (code) => context
                                .read<OnboardingBloc>()
                                .add(OnboardingTargetLangChanged(code)),
                            excludeCode: state.sourceLang,
                          ),
                          _buildLevelSelection(context, state),
                          _buildDailyGoalSelection(context, state),
                        ],
                      ),
                    ),
                    _buildBottomBar(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelection(
    BuildContext context, {
    required OnboardingState state,
    required String title,
    required String subtitle,
    required String selectedValue,
    required Function(String) onSelect,
    String? excludeCode,
  }) {
    final languages = OnboardingBloc.supportedLanguages
        .where((code) => code != excludeCode)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsive.spacingXL),
        Text(title,
            style: context.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: context.responsive.spacingXS),
        Text(subtitle,
            style: context.textTheme.bodyLarge
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        SizedBox(height: context.responsive.spacingL),
        Expanded(
          child: ListView.builder(
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final code = languages[index];
              final isSelected = code == selectedValue;
              final langName = LanguageManager.instance.getLanguageName(code);

              return Padding(
                padding:
                    EdgeInsets.symmetric(vertical: context.responsive.spacingS),
                child: InkWell(
                  onTap: () => onSelect(code),
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusL),
                  child: Container(
                    padding: EdgeInsets.all(context.responsive.spacingL),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colors.primaryContainer.withOpacity(0.2)
                          : context.colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusL),
                      border: Border.all(
                        color: isSelected
                            ? context.colors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(_getFlag(code),
                            style: TextStyle(
                                fontSize: context.responsive
                                    .value(mobile: 28, tablet: 32))),
                        SizedBox(width: context.responsive.spacingM),
                        Expanded(
                          child: Text(
                            langName,
                            style: GoogleFonts.poppins(
                              fontSize: context.responsive.fontSizeH3,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? context.colors.primary
                                  : context.colors.onSurface,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: context.colors.primary,
                              size: context.responsive.iconSizeL),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelection(BuildContext context, OnboardingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsive.spacingXL),
        Text('onboard_level_title'.tr(),
            style: context.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: context.responsive.spacingXS),
        Text('onboard_level_desc'.tr(),
            style: context.textTheme.bodyLarge
                ?.copyWith(color: context.colors.onSurfaceVariant)),
        SizedBox(height: context.responsive.spacingL),
        Expanded(
          child: ListView.builder(
            itemCount: OnboardingBloc.difficultyLevels.length,
            itemBuilder: (context, index) {
              final levelKey = OnboardingBloc.difficultyLevels[index];
              final isSelected = levelKey == state.selectedLevel;
              return Padding(
                padding:
                    EdgeInsets.symmetric(vertical: context.responsive.spacingS),
                child: InkWell(
                  onTap: () => context
                      .read<OnboardingBloc>()
                      .add(OnboardingLevelChanged(levelKey)),
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusL),
                  child: Container(
                    padding: EdgeInsets.all(context.responsive.spacingL),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colors.primaryContainer.withOpacity(0.2)
                          : context.colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusL),
                      border: Border.all(
                        color: isSelected
                            ? context.colors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'level_$levelKey'.tr(),
                                style: GoogleFonts.poppins(
                                  fontSize: context.responsive.fontSizeH3,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? context.colors.primary
                                      : context.colors.onSurface,
                                ),
                              ),
                              SizedBox(height: context.responsive.spacingS),
                              Text(
                                'level_${levelKey}_desc'.tr(),
                                style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: context.colors.primary,
                              size: context.responsive.iconSizeL),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyGoalSelection(BuildContext context, OnboardingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsive.spacingXL),
        Text(
          'Günlük Hedefini Belirle',
          style: context.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: context.responsive.spacingXS),
        Text(
          'Her gün kaç kelime öğrenmek istiyorsun? İstersen ayarlarda değiştirebilirsin.',
          style: context.textTheme.bodyLarge
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        SizedBox(height: context.responsive.spacingXL),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            itemCount: OnboardingBloc.dailyGoalOptions.length,
            itemBuilder: (context, index) {
              final goal = OnboardingBloc.dailyGoalOptions[index];
              final isSelected = goal == state.selectedDailyGoal;
              return GestureDetector(
                onTap: () => context
                    .read<OnboardingBloc>()
                    .add(OnboardingDailyGoalChanged(goal)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              context.colors.primary,
                              context.colors.secondary
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : context.colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(
                        context.responsive.borderRadiusXL),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : context.colors.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$goal',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : context.colors.onSurface,
                        ),
                      ),
                      Text(
                        'kelime/gün',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withOpacity(0.9)
                              : context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, OnboardingState state) {
    return Padding(
      padding: EdgeInsets.only(top: context.responsive.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (state.currentPage > 0)
            TextButton(
              onPressed: () => context
                  .read<OnboardingBloc>()
                  .add(const OnboardingPreviousPage()),
              child: Text(
                'btn_back'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeBody,
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () {
                    if (!state.isLastPage) {
                      context
                          .read<OnboardingBloc>()
                          .add(const OnboardingNextPage());
                    } else {
                      context
                          .read<OnboardingBloc>()
                          .add(const OnboardingCompleted());
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              disabledBackgroundColor: context.colors.primary.withOpacity(0.6),
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.spacingXL,
                vertical: context.responsive.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(context.responsive.borderRadiusXL),
              ),
            ),
            child: state.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: context.colors.onPrimary),
                  )
                : Text(
                    state.isLastPage ? 'btn_start'.tr() : 'btn_next'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: context.responsive.fontSizeH3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getFlag(String langCode) {
    switch (langCode.split('-')[0]) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇬🇧';
      case 'es':
        return '🇪🇸';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'pt':
        return '🇵🇹';
      default:
        return '🏳️';
    }
  }
}
