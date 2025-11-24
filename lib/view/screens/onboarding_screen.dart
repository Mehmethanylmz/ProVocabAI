import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../viewmodel/onboarding_viewmodel.dart';
import 'main_screen.dart';
import '../../core/extensions/responsive_extension.dart';
import '../../core/constants/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _OnboardingContent(),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: context.responsive.paddingPage,
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: viewModel.currentPage,
                  children: [
                    _buildLanguageSelection(
                      context,
                      'onboard_lang_source_title'.tr(),
                      'onboard_lang_source_desc'.tr(),
                      viewModel.selectedSourceLang,
                      viewModel.languages,
                      (val) => viewModel.setSourceLang(val),
                    ),
                    _buildLanguageSelection(
                      context,
                      'onboard_lang_target_title'.tr(),
                      'onboard_lang_target_desc'.tr(),
                      viewModel.selectedTargetLang,
                      viewModel.languages,
                      (val) => viewModel.setTargetLang(val),
                      exclude: viewModel.selectedSourceLang,
                    ),
                    _buildLevelSelection(context, viewModel),
                  ],
                ),
              ),
              _buildBottomBar(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelection(
    BuildContext context,
    String title,
    String subtitle,
    String selectedValue,
    Map<String, String> options,
    Function(String) onSelect, {
    String? exclude,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsive.spacingXL),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeH1,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: context.responsive.spacingXS),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeBody,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: context.responsive.spacingL),
        Expanded(
          child: ListView(
            children: options.entries.map((entry) {
              if (entry.key == exclude) return const SizedBox.shrink();

              final isSelected = entry.key == selectedValue;
              return Padding(
                padding:
                    EdgeInsets.symmetric(vertical: context.responsive.spacingS),
                child: InkWell(
                  onTap: () => onSelect(entry.key),
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusL),
                  child: Container(
                    padding: EdgeInsets.all(context.responsive.spacingL),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusL),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _getFlag(entry.key),
                          style: TextStyle(
                            fontSize: context.responsive.value(
                              mobile: 28,
                              tablet: 32,
                              desktop: 36,
                            ),
                          ),
                        ),
                        SizedBox(width: context.responsive.spacingM),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: GoogleFonts.poppins(
                              fontSize: context.responsive.fontSizeH3,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: context.responsive.iconSizeL,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelection(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsive.spacingXL),
        Text(
          'onboard_level_title'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeH1,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: context.responsive.spacingXS),
        Text(
          'onboard_level_desc'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeBody,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: context.responsive.spacingL),
        Expanded(
          child: ListView(
            children: viewModel.levels.entries.map((entry) {
              final isSelected = entry.key == viewModel.selectedLevel;
              return Padding(
                padding:
                    EdgeInsets.symmetric(vertical: context.responsive.spacingS),
                child: InkWell(
                  onTap: () => viewModel.setLevel(entry.key),
                  borderRadius:
                      BorderRadius.circular(context.responsive.borderRadiusL),
                  child: Container(
                    padding: EdgeInsets.all(context.responsive.spacingL),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusL),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _getLevelTitle(entry.key),
                                style: GoogleFonts.poppins(
                                  fontSize: context.responsive.fontSizeH3,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: context.responsive.iconSizeL,
                              ),
                          ],
                        ),
                        SizedBox(height: context.responsive.spacingS),
                        Text(
                          _getLevelDescription(entry.key),
                          style: GoogleFonts.poppins(
                            fontSize: context.responsive.fontSizeBody,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, OnboardingViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.only(top: context.responsive.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (viewModel.currentPage > 0)
            TextButton(
              onPressed: viewModel.previousPage,
              child: Text(
                'btn_back'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeBody,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: () async {
              if (viewModel.currentPage < 2) {
                viewModel.nextPage();
              } else {
                await context.setLocale(Locale(viewModel.selectedSourceLang));

                await viewModel.completeOnboarding();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.spacingXL,
                vertical: context.responsive.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(context.responsive.borderRadiusXL),
              ),
              elevation: context.responsive.elevationMedium,
            ),
            child: Text(
              viewModel.currentPage == 2 ? 'btn_start'.tr() : 'btn_next'.tr(),
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
    switch (langCode) {
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

  String _getLevelTitle(String levelKey) {
    switch (levelKey) {
      case 'beginner':
        return 'level_beginner'.tr();
      case 'intermediate':
        return 'level_intermediate'.tr();
      case 'advanced':
        return 'level_advanced'.tr();
      default:
        return levelKey;
    }
  }

  String _getLevelDescription(String levelKey) {
    switch (levelKey) {
      case 'beginner':
        return 'level_beginner_desc'.tr();
      case 'intermediate':
        return 'level_intermediate_desc'.tr();
      case 'advanced':
        return 'level_advanced_desc'.tr();
      default:
        return '';
    }
  }
}
