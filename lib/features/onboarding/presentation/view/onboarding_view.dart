import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/lang/language_manager.dart'; // LanguageManager eklendi
import '../../../../core/init/navigation/navigation_service.dart';
import '../view_model/onboarding_view_model.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  // Dillerin kendi dillerindeki isimleri (Çevrilmemeli)
  final Map<String, String> _languageNames = const {
    'tr': 'Türkçe',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'fr': 'Français',
    'pt': 'Português',
  };

  @override
  Widget build(BuildContext context) {
    // ViewModel'i Context üzerinden alıyoruz (Provider)
    final viewModel = context.watch<OnboardingViewModel>();

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Padding(
          padding: context.responsive.paddingPage,
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: viewModel.currentPage,
                  children: [
                    // Sayfa 0: Kaynak Dil Seçimi
                    _buildLanguageSelection(
                      context,
                      title: 'onboard_lang_source_title'.tr(),
                      subtitle: 'onboard_lang_source_desc'.tr(),
                      selectedValue: viewModel.selectedSourceLang,
                      onSelect: (code) => viewModel.setSourceLang(code),
                    ),
                    // Sayfa 1: Hedef Dil Seçimi
                    _buildLanguageSelection(
                      context,
                      title: 'onboard_lang_target_title'.tr(),
                      subtitle: 'onboard_lang_target_desc'.tr(),
                      selectedValue: viewModel.selectedTargetLang,
                      onSelect: (code) => viewModel.setTargetLang(code),
                      excludeCode: viewModel.selectedSourceLang,
                    ),
                    // Sayfa 2: Seviye Seçimi
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
    BuildContext context, {
    required String title,
    required String subtitle,
    required String selectedValue,
    required Function(String) onSelect,
    String? excludeCode,
  }) {
    // ViewModel'deki desteklenen diller listesini kullanıyoruz
    final viewModel = context.read<OnboardingViewModel>();
    final languages = viewModel.supportedLanguages
        .where((code) => code != excludeCode)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsive.spacingXL),
        Text(
          title,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),
        ),
        SizedBox(height: context.responsive.spacingXS),
        Text(
          subtitle,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.responsive.spacingL),
        Expanded(
          child: ListView.builder(
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final code = languages[index];
              final isSelected = code == selectedValue;
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
                        Text(
                          _getFlag(code),
                          style: TextStyle(
                            fontSize: context.responsive
                                .value(mobile: 28, tablet: 32, desktop: 36),
                          ),
                        ),
                        SizedBox(width: context.responsive.spacingM),
                        Expanded(
                          child: Text(
                            _languageNames[code] ?? code.toUpperCase(),
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
                          Icon(
                            Icons.check_circle,
                            color: context.colors.primary,
                            size: context.responsive.iconSizeL,
                          ),
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

  Widget _buildLevelSelection(
      BuildContext context, OnboardingViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.responsive.spacingXL),
        Text(
          'onboard_level_title'.tr(),
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),
        ),
        SizedBox(height: context.responsive.spacingXS),
        Text(
          'onboard_level_desc'.tr(),
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.responsive.spacingL),
        Expanded(
          child: ListView.builder(
            itemCount: viewModel.difficultyLevels.length,
            itemBuilder: (context, index) {
              final levelKey = viewModel.difficultyLevels[index];
              final isSelected = levelKey == viewModel.selectedLevel;

              // JSON'dan dinamik çeviri: 'level_beginner', 'level_beginner_desc' vb.
              final title = 'level_$levelKey'.tr();
              final desc = 'level_${levelKey}_desc'.tr();

              return Padding(
                padding:
                    EdgeInsets.symmetric(vertical: context.responsive.spacingS),
                child: InkWell(
                  onTap: () => viewModel.setLevel(levelKey),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: context.responsive.fontSizeH3,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? context.colors.primary
                                      : context.colors.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: context.colors.primary,
                                size: context.responsive.iconSizeL,
                              ),
                          ],
                        ),
                        SizedBox(height: context.responsive.spacingS),
                        Text(
                          desc,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
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
                  color: context.colors.onSurfaceVariant,
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
                // --- KRİTİK DÜZELTME: Locale Değişimi ---

                // 1. Seçilen dil kodunu al (örn: 'en')
                final selectedCode = viewModel.selectedSourceLang;

                // 2. LanguageManager listesinden bu koda sahip GERÇEK Locale nesnesini bul
                final targetLocale =
                    LanguageManager.instance.supportedLocales.firstWhere(
                  (locale) => locale.languageCode == selectedCode,
                  orElse: () => LanguageManager
                      .instance.supportedLocales.first, // Varsayılan
                );

                // 3. EasyLocalization'a bu geçerli nesneyi ver
                await context.setLocale(targetLocale);

                // 4. Tamamlama işlemleri
                await viewModel.completeOnboarding();

                if (!context.mounted) return;

                // 5. Ana Sayfaya Git
                NavigationService.instance
                    .navigateToPageClear(path: NavigationConstants.MAIN);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.spacingXL,
                vertical: context.responsive.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(context.responsive.borderRadiusXL),
              ),
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
}
