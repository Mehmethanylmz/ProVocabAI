// lib/features/settings/presentation/view/settings_view.dart
//
// FIX: supportedLanguageCodes getter yok →
//      LanguageManager.instance.supportedLocales.map(locale.languageCode) kullan

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/lang/language_manager.dart';
import '../state/settings_bloc.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<SettingsBloc>()..add(const SettingsLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
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
            body: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: context.colors.primary))
                : ListView(
                    padding: context.responsive.paddingPage,
                    children: [
                      _buildSectionHeader(context, 'Görünüm'),
                      _buildThemeSelector(context, state),
                      Divider(
                          height: context.responsive.spacingXL,
                          color: context.colors.outlineVariant),
                      _buildSectionHeader(context, 'language_settings'.tr()),
                      _buildLanguageItem(
                        context,
                        title: 'native_language'.tr(),
                        currentValue: state.sourceLang,
                        onChanged: (val) => context
                            .read<SettingsBloc>()
                            .add(SettingsSourceLangChanged(val!)),
                      ),
                      _buildLanguageItem(
                        context,
                        title: 'target_language'.tr(),
                        currentValue: state.targetLang,
                        onChanged: (val) => context
                            .read<SettingsBloc>()
                            .add(SettingsTargetLangChanged(val!)),
                      ),
                      _buildLevelItem(context, state),
                      Divider(
                          height: context.responsive.spacingXL,
                          color: context.colors.outlineVariant),
                      _buildSectionHeader(context, 'study_settings'.tr()),
                      _buildGoalSlider(context, state),
                      SizedBox(height: context.responsive.spacingS),
                      _buildBatchSizeSlider(context, state),
                      _buildAutoPlaySwitch(context, state),
                    ],
                  ),
          );
        },
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

  Widget _buildThemeSelector(BuildContext context, SettingsState state) {
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
            groupValue: state.themeMode,
            activeColor: context.colors.primary,
            onChanged: (val) => context
                .read<SettingsBloc>()
                .add(SettingsThemeModeChanged(val!)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Aydınlık (Light)'),
            value: ThemeMode.light,
            groupValue: state.themeMode,
            activeColor: context.colors.primary,
            onChanged: (val) => context
                .read<SettingsBloc>()
                .add(SettingsThemeModeChanged(val!)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Karanlık (Dark)'),
            value: ThemeMode.dark,
            groupValue: state.themeMode,
            activeColor: context.colors.primary,
            onChanged: (val) => context
                .read<SettingsBloc>()
                .add(SettingsThemeModeChanged(val!)),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context, {
    required String title,
    required String currentValue,
    required Function(String?) onChanged,
  }) {
    // LanguageManager.supportedLanguageCodes YOKTUR.
    // supportedLocales listesini map'leyerek short code alıyoruz.
    final languageCodes = LanguageManager.instance.supportedLocales
        .map((l) => l.languageCode)
        .toList();

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
          value: languageCodes.contains(currentValue) ? currentValue : null,
          underline: const SizedBox(),
          onChanged: onChanged,
          items: languageCodes.map((code) {
            final label = LanguageManager.instance.getLanguageName(code);
            return DropdownMenuItem(
              value: code,
              child: Text(label, style: context.textTheme.bodyMedium),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLevelItem(BuildContext context, SettingsState state) {
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
          value: levels.containsKey(state.proficiencyLevel)
              ? state.proficiencyLevel
              : 'beginner',
          underline: const SizedBox(),
          onChanged: (val) => context
              .read<SettingsBloc>()
              .add(SettingsProficiencyChanged(val!)),
          items: levels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildGoalSlider(BuildContext context, SettingsState state) {
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
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 18, color: context.colors.primary),
              SizedBox(width: context.responsive.spacingXS),
              Text('${'daily_goal'.tr()}: ',
                  style: context.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text('${state.dailyGoal} kelime',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  )),
            ],
          ),
          Slider(
            value: state.dailyGoal.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            label: '${state.dailyGoal}',
            activeColor: context.colors.primary,
            onChanged: (val) => context
                .read<SettingsBloc>()
                .add(SettingsDailyGoalChanged(val.toInt())),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchSizeSlider(BuildContext context, SettingsState state) {
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
          Row(
            children: [
              Icon(Icons.format_list_numbered_rounded,
                  size: 18, color: context.colors.secondary),
              SizedBox(width: context.responsive.spacingXS),
              Text('Test soru sayısı: ',
                  style: context.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text('${state.batchSize} soru',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.secondary,
                  )),
            ],
          ),
          Slider(
            value: state.batchSize.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: '${state.batchSize} soru',
            activeColor: context.colors.secondary,
            onChanged: (val) => context
                .read<SettingsBloc>()
                .add(SettingsBatchSizeChanged(val.toInt())),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPlaySwitch(BuildContext context, SettingsState state) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusM),
      ),
      child: SwitchListTile(
        title: Text('auto_play_sound'.tr(), style: context.textTheme.bodyLarge),
        value: state.autoPlaySound,
        activeThumbColor: context.colors.primary,
        onChanged: (val) =>
            context.read<SettingsBloc>().add(SettingsAutoPlayChanged(val)),
      ),
    );
  }
}
