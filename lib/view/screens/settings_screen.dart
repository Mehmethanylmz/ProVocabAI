import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../../viewmodel/settings_viewmodel.dart';
import '../../viewmodel/test_menu_viewmodel.dart';
import 'onboarding_screen.dart';
import '../../core/extensions/responsive_extension.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const SettingsScreen({super.key, this.isFirstLaunch = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _currentBatchSize;
  late bool _currentAutoPlaySound;
  late String _currentSourceLang;
  late String _currentTargetLang;
  late String _currentProficiencyLevel;

  bool _isInitialized = false;

  // Localization key'leri kullanıyoruz
  final Map<String, String> languages = {
    'tr': 'Türkçe',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'fr': 'Français',
    'pt': 'Português',
  };

  // Level'lar için localization key'leri
  final Map<String, String> levels = {
    'beginner': 'level_beginner'.tr(),
    'intermediate': 'level_intermediate'.tr(),
    'advanced': 'level_advanced'.tr(),
  };

  Future<void> _saveSettings(BuildContext context) async {
    final viewModel = context.read<SettingsViewModel>();

    await viewModel.updateBatchSize(_currentBatchSize);
    await viewModel.updateAutoPlaySound(_currentAutoPlaySound);
    await viewModel.updateLanguages(_currentSourceLang, _currentTargetLang);
    await viewModel.updateLevel(_currentProficiencyLevel);

    if (mounted) {
      await context.setLocale(Locale(_currentSourceLang));
    }

    if (widget.isFirstLaunch) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch_v2', false);
    }

    if (!mounted) return;

    context.read<HomeViewModel>().loadHomeData();
    context.read<TestMenuViewModel>().loadTestData();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (!_isInitialized) {
          _currentBatchSize = viewModel.batchSize;
          _currentAutoPlaySound = viewModel.autoPlaySound;
          _currentSourceLang = viewModel.sourceLang;
          _currentTargetLang = viewModel.targetLang;
          _currentProficiencyLevel = viewModel.proficiencyLevel;
          _isInitialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'settings_title'.tr(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: context.responsive.fontSizeH2,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
          ),
          body: ListView(
            padding: context.responsive.paddingPage,
            children: [
              _buildSectionHeader('language_settings'.tr()),
              _buildLanguageSettingItem(
                context,
                'native_language'.tr(),
                languages[_currentSourceLang] ?? '',
                _currentSourceLang,
                (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _currentSourceLang = newValue;
                      if (_currentTargetLang == newValue) {
                        _currentTargetLang = newValue == 'en' ? 'tr' : 'en';
                      }
                    });
                  }
                },
              ),
              _buildLanguageSettingItem(
                context,
                'target_language'.tr(),
                languages[_currentTargetLang] ?? '',
                _currentTargetLang,
                (newValue) {
                  if (newValue != null && newValue != _currentSourceLang) {
                    setState(() => _currentTargetLang = newValue);
                  }
                },
                enabled: _currentTargetLang != _currentSourceLang,
              ),
              _buildLevelSettingItem(context),
              Divider(height: context.responsive.spacingXL),
              _buildSectionHeader('study_settings'.tr()),
              _buildBatchSizeSlider(context),
              _buildAutoPlaySwitch(context),
              SizedBox(height: context.responsive.spacingXL),
              _buildSaveButton(context),
              if (!widget.isFirstLaunch) ...[
                SizedBox(height: context.responsive.spacingL),
                _buildResetButton(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.responsive.spacingS,
        horizontal: context.responsive.spacingM,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: context.responsive.fontSizeCaption,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLanguageSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    String currentValue,
    Function(String?) onChanged, {
    bool enabled = true,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeBody,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeCaption,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: DropdownButton<String>(
          value: currentValue,
          underline: const SizedBox(),
          onChanged: enabled ? onChanged : null,
          items: languages.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              enabled: e.key != _currentSourceLang ||
                  title != 'target_language'.tr(),
              child: Text(
                e.value,
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeBody,
                  color: (e.key == _currentSourceLang &&
                          title == 'target_language'.tr())
                      ? AppColors.textDisabled
                      : AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLevelSettingItem(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          'difficulty_level'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeBody,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'difficulty_level_desc'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeCaption,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: DropdownButton<String>(
          value: _currentProficiencyLevel,
          underline: const SizedBox(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _currentProficiencyLevel = newValue);
            }
          },
          items: levels.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(
                e.value,
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeBody,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBatchSizeSlider(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      padding: EdgeInsets.all(context.responsive.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'daily_goal'.tr()}: $_currentBatchSize',
            style: GoogleFonts.poppins(
              fontSize: context.responsive.fontSizeBody,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.responsive.spacingM),
          Slider(
            value: _currentBatchSize.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: _currentBatchSize.toString(),
            activeColor: AppColors.primary,
            inactiveColor: AppColors.borderLight,
            onChanged: (val) => setState(() => _currentBatchSize = val.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPlaySwitch(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          'auto_play_sound'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeBody,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        value: _currentAutoPlaySound,
        activeColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withOpacity(0.3),
        onChanged: (val) => setState(() => _currentAutoPlaySound = val),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          padding: EdgeInsets.symmetric(vertical: context.responsive.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(context.responsive.borderRadiusL),
          ),
          elevation: context.responsive.elevationMedium,
        ),
        onPressed: () => _saveSettings(context),
        child: Text(
          'btn_save'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeH3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isFirstLaunch_v2', true);
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const OnboardingScreen(),
              ),
              (route) => false,
            );
          }
        },
        child: Text(
          'reset_onboarding'.tr(),
          style: GoogleFonts.poppins(
            fontSize: context.responsive.fontSizeBody,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
