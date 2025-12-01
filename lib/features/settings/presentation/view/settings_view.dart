import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../../../../core/init/lang/language_manager.dart';
import '../viewmodel/settings_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseView<SettingsViewModel>(
      viewModel: locator<SettingsViewModel>(),
      onModelReady: (model) {
        model.setContext(context);
        model.loadSettings();
      },
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'settings_title'.tr(),
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onPrimary,
              ),
            ),
            centerTitle: true,
            backgroundColor: context.colors.primary,
            iconTheme: IconThemeData(color: context.colors.onPrimary),
          ),
          body: viewModel.isLoading
              ? Center(
                  child:
                      CircularProgressIndicator(color: context.colors.primary))
              : ListView(
                  padding: context.responsive.paddingPage,
                  children: [
                    _buildSectionHeader(context, 'Görünüm'),
                    _buildThemeSelector(context, viewModel),
                    Divider(
                        height: context.responsive.spacingXL,
                        color: context.colors.outlineVariant),
                    _buildSectionHeader(context, 'language_settings'.tr()),
                    _buildLanguageItem(
                      context,
                      title: 'native_language'.tr(),
                      currentValue: viewModel.sourceLang,
                      onChanged: (val) =>
                          viewModel.updateLanguages(val!, viewModel.targetLang),
                    ),
                    _buildLanguageItem(
                      context,
                      title: 'target_language'.tr(),
                      currentValue: viewModel.targetLang,
                      onChanged: (val) =>
                          viewModel.updateLanguages(viewModel.sourceLang, val!),
                      enabled: true,
                    ),
                    _buildLevelItem(context, viewModel),
                    Divider(
                        height: context.responsive.spacingXL,
                        color: context.colors.outlineVariant),
                    _buildSectionHeader(context, 'study_settings'.tr()),
                    _buildBatchSizeSlider(context, viewModel),
                    _buildAutoPlaySwitch(context, viewModel),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, SettingsViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
      ),
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Sistem Teması'),
            value: ThemeMode.system,
            groupValue: viewModel.themeMode,
            activeColor: context.colors.primary,
            onChanged: (val) => viewModel.updateThemeMode(val!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Aydınlık (Light)'),
            value: ThemeMode.light,
            groupValue: viewModel.themeMode,
            activeColor: context.colors.primary,
            onChanged: (val) => viewModel.updateThemeMode(val!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Karanlık (Dark)'),
            value: ThemeMode.dark,
            groupValue: viewModel.themeMode,
            activeColor: context.colors.primary,
            onChanged: (val) => viewModel.updateThemeMode(val!),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.responsive.spacingS,
        horizontal: context.responsive.spacingM,
      ),
      child: Text(
        title,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.colors.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context, {
    required String title,
    required String currentValue,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    final supportedLocales = LanguageManager.instance.supportedLocales;

    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      decoration: BoxDecoration(
        color: context.colors.surface,
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
        title: Text(title, style: context.textTheme.bodyLarge),
        trailing: DropdownButton<String>(
          value: currentValue,
          underline: const SizedBox(),
          onChanged: enabled ? onChanged : null,
          items: supportedLocales.map((locale) {
            final value = LanguageManager.instance.getLocaleString(locale);
            final label =
                LanguageManager.instance.getLanguageName(locale.languageCode);
            return DropdownMenuItem(
              value: value,
              child: Text(label, style: context.textTheme.bodyMedium),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLevelItem(BuildContext context, SettingsViewModel viewModel) {
    final levels = {
      'beginner': 'level_beginner'.tr(),
      'intermediate': 'level_intermediate'.tr(),
      'advanced': 'level_advanced'.tr(),
    };

    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
      ),
      child: ListTile(
        title:
            Text('difficulty_level'.tr(), style: context.textTheme.bodyLarge),
        subtitle: Text('difficulty_level_desc'.tr(),
            style: context.textTheme.bodySmall),
        trailing: DropdownButton<String>(
          value: viewModel.proficiencyLevel,
          underline: const SizedBox(),
          onChanged: (val) => viewModel.updateLevel(val!),
          items: levels.entries.map((e) {
            return DropdownMenuItem(value: e.key, child: Text(e.value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBatchSizeSlider(
      BuildContext context, SettingsViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      padding: EdgeInsets.all(context.responsive.spacingM),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'daily_goal'.tr()}: ${viewModel.batchSize}',
            style: context.textTheme.bodyLarge,
          ),
          Slider(
            value: viewModel.batchSize.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: viewModel.batchSize.toString(),
            activeColor: context.colors.primary,
            onChanged: (val) => viewModel.updateBatchSize(val.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPlaySwitch(
      BuildContext context, SettingsViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
      ),
      child: SwitchListTile(
        title: Text('auto_play_sound'.tr(), style: context.textTheme.bodyLarge),
        value: viewModel.autoPlaySound,
        activeThumbColor: context.colors.primary,
        onChanged: (val) => viewModel.updateAutoPlaySound(val),
      ),
    );
  }
}
