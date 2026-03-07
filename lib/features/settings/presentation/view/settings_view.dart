// lib/features/settings/presentation/view/settings_view.dart
//
// FAZ 14 — F14-01..F14-07: Ayarlar ekranı profesyonelleşme
//   F14-01: Uygulama dili (easy_localization context.setLocale)
//   F14-02: Hesap sil + re-auth + Firestore temizleme
//   F14-03: Bildirim saati (TimePicker)
//   F14-04: Uygulama hakkında (versiyon, lisanslar)
//   F14-05: Önbellek temizle
//   F14-06: Destek / geri bildirim
//   F14-07: Profesyonel gruplandırılmış UI (sections)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/init/lang/language_manager.dart';
import '../../../../firebase/auth/firebase_auth_service.dart';
import '../../../auth/presentation/state/auth_bloc.dart';
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
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              centerTitle: true,
            ),
            body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    // ── Görünüm ──────────────────────────────────────────
                    _SectionHeader(
                        icon: Icons.palette_rounded, title: 'Görünüm'),
                    _ThemeSection(state: state),

                    const SizedBox(height: 20),

                    // ── Uygulama Dili (F14-01) ────────────────────────────
                    _SectionHeader(
                        icon: Icons.language_rounded, title: 'Uygulama Dili'),
                    _AppLocaleSection(),

                    const SizedBox(height: 20),

                    // ── Kelime Ayarları ───────────────────────────────────
                    _SectionHeader(
                        icon: Icons.menu_book_rounded,
                        title: 'Kelime Ayarları'),
                    _SettingsCard(
                      children: [
                        _LangDropdownTile(
                          title: 'native_language'.tr(),
                          icon: Icons.home_rounded,
                          currentValue: state.sourceLang,
                          onChanged: (val) => context
                              .read<SettingsBloc>()
                              .add(SettingsSourceLangChanged(val!)),
                        ),
                        _Divider(),
                        _LangDropdownTile(
                          title: 'target_language'.tr(),
                          icon: Icons.flag_rounded,
                          currentValue: state.targetLang,
                          onChanged: (val) => context
                              .read<SettingsBloc>()
                              .add(SettingsTargetLangChanged(val!)),
                        ),
                        _Divider(),
                        _LevelDropdownTile(state: state),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Çalışma Ayarları ──────────────────────────────────
                    _SectionHeader(
                        icon: Icons.school_rounded,
                        title: 'Çalışma Ayarları'),
                    _SettingsCard(
                      children: [
                        _GoalSliderTile(state: state),
                        _Divider(),
                        _BatchSizeSliderTile(state: state),
                        _Divider(),
                        _AutoPlayTile(state: state),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Bildirimler (F14-03) ───────────────────────────────
                    _SectionHeader(
                        icon: Icons.notifications_rounded,
                        title: 'Bildirimler'),
                    _NotificationSection(state: state),

                    const SizedBox(height: 20),

                    // ── Veri Yönetimi (F14-05) ────────────────────────────
                    _SectionHeader(
                        icon: Icons.storage_rounded,
                        title: 'Veri Yönetimi'),
                    _SettingsCard(
                      children: [
                        _ClearCacheTile(),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Destek (F14-06) ───────────────────────────────────
                    _SectionHeader(
                        icon: Icons.support_agent_rounded, title: 'Destek'),
                    _SettingsCard(
                      children: [
                        _FeedbackTile(),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Uygulama Hakkında (F14-04) ────────────────────────
                    _SectionHeader(
                        icon: Icons.info_rounded, title: 'Hakkında'),
                    _SettingsCard(
                      children: [
                        _AboutTile(),
                        _Divider(),
                        _LicensesTile(),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Hesap (F14-02) ────────────────────────────────────
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final isGuest =
                            authState is AuthAuthenticated && authState.isGuest;
                        if (isGuest) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                                icon: Icons.manage_accounts_rounded,
                                title: 'Hesap'),
                            _SettingsCard(
                              children: [
                                _DeleteAccountTile(),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
          );
        },
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Card ──────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}

// ── F14-07: Theme Section ──────────────────────────────────────────────────────

class _ThemeSection extends StatelessWidget {
  final SettingsState state;
  const _ThemeSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        _ThemeRadioTile(
          title: 'Sistem Teması',
          subtitle: 'Cihaz ayarına göre',
          icon: Icons.brightness_auto_rounded,
          value: ThemeMode.system,
          groupValue: state.themeMode,
        ),
        _Divider(),
        _ThemeRadioTile(
          title: 'Aydınlık',
          subtitle: 'Light mode',
          icon: Icons.light_mode_rounded,
          value: ThemeMode.light,
          groupValue: state.themeMode,
        ),
        _Divider(),
        _ThemeRadioTile(
          title: 'Karanlık',
          subtitle: 'Dark mode',
          icon: Icons.dark_mode_rounded,
          value: ThemeMode.dark,
          groupValue: state.themeMode,
        ),
      ],
    );
  }
}

class _ThemeRadioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode groupValue;
  const _ThemeRadioTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = value == groupValue;
    return ListTile(
      leading: Icon(icon,
          color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5),
          size: 22),
      title: Text(title,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.5))),
      trailing: Radio<ThemeMode>(
        value: value,
        groupValue: groupValue,
        activeColor: scheme.primary,
        onChanged: (val) => context
            .read<SettingsBloc>()
            .add(SettingsThemeModeChanged(val!)),
      ),
      onTap: () => context
          .read<SettingsBloc>()
          .add(SettingsThemeModeChanged(value)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ── F14-01: App Locale Section ─────────────────────────────────────────────────

class _AppLocaleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentLocale = context.locale;
    final supportedLocales = LanguageManager.instance.supportedLocales;
    final currentCode = currentLocale.languageCode;

    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.translate_rounded,
                  size: 20, color: scheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Arayüz Dili',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
              DropdownButton<String>(
                value: supportedLocales
                        .any((l) => l.languageCode == currentCode)
                    ? currentCode
                    : 'tr',
                underline: const SizedBox(),
                isDense: true,
                onChanged: (code) {
                  if (code == null) return;
                  final locale = LanguageManager.instance
                      .getLocaleFromString(code);
                  context.setLocale(locale);
                },
                items: supportedLocales.map((locale) {
                  final code = locale.languageCode;
                  final label = LanguageManager.instance.getLanguageName(code);
                  return DropdownMenuItem(
                    value: code,
                    child: Text(label,
                        style: GoogleFonts.inter(fontSize: 13)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Language Dropdown Tile ─────────────────────────────────────────────────────

class _LangDropdownTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String currentValue;
  final Function(String?) onChanged;
  const _LangDropdownTile({
    required this.title,
    required this.icon,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final languageCodes = LanguageManager.instance.supportedLocales
        .map((l) => l.languageCode)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: GoogleFonts.inter(fontSize: 14)),
          ),
          DropdownButton<String>(
            value: languageCodes.contains(currentValue) ? currentValue : null,
            underline: const SizedBox(),
            isDense: true,
            onChanged: onChanged,
            items: languageCodes.map((code) {
              final label = LanguageManager.instance.getLanguageName(code);
              return DropdownMenuItem(
                value: code,
                child: Text(label, style: GoogleFonts.inter(fontSize: 13)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Level Dropdown Tile ────────────────────────────────────────────────────────

class _LevelDropdownTile extends StatelessWidget {
  final SettingsState state;
  const _LevelDropdownTile({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levels = {
      'beginner': 'level_beginner'.tr(),
      'intermediate': 'level_intermediate'.tr(),
      'advanced': 'level_advanced'.tr(),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 20, color: scheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('difficulty_level'.tr(),
                    style: GoogleFonts.inter(fontSize: 14)),
                Text('difficulty_level_desc'.tr(),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          DropdownButton<String>(
            value: levels.containsKey(state.proficiencyLevel)
                ? state.proficiencyLevel
                : 'beginner',
            underline: const SizedBox(),
            isDense: true,
            onChanged: (val) => context
                .read<SettingsBloc>()
                .add(SettingsProficiencyChanged(val!)),
            items: levels.entries
                .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: GoogleFonts.inter(fontSize: 13))))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Goal Slider Tile ───────────────────────────────────────────────────────────

class _GoalSliderTile extends StatelessWidget {
  final SettingsState state;
  const _GoalSliderTile({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded,
                  size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text('${'daily_goal'.tr()}: ',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text('${state.dailyGoal} kelime',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary)),
            ],
          ),
          Slider(
            value: state.dailyGoal.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            label: '${state.dailyGoal}',
            activeColor: scheme.primary,
            onChanged: (val) => context
                .read<SettingsBloc>()
                .add(SettingsDailyGoalChanged(val.toInt())),
          ),
        ],
      ),
    );
  }
}

// ── Batch Size Slider Tile ─────────────────────────────────────────────────────

class _BatchSizeSliderTile extends StatelessWidget {
  final SettingsState state;
  const _BatchSizeSliderTile({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_list_numbered_rounded,
                  size: 18, color: scheme.secondary),
              const SizedBox(width: 8),
              Text('Test soru sayısı: ',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text('${state.batchSize}',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.secondary)),
            ],
          ),
          Slider(
            value: state.batchSize.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: '${state.batchSize}',
            activeColor: scheme.secondary,
            onChanged: (val) => context
                .read<SettingsBloc>()
                .add(SettingsBatchSizeChanged(val.toInt())),
          ),
        ],
      ),
    );
  }
}

// ── AutoPlay Switch ────────────────────────────────────────────────────────────

class _AutoPlayTile extends StatelessWidget {
  final SettingsState state;
  const _AutoPlayTile({required this.state});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        state.autoPlaySound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: state.autoPlaySound
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        size: 22,
      ),
      title: Text('auto_play_sound'.tr(),
          style: GoogleFonts.inter(fontSize: 14)),
      subtitle: Text(
        state.autoPlaySound ? 'Kelime okunur' : 'Ses kapalı',
        style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5)),
      ),
      value: state.autoPlaySound,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (val) =>
          context.read<SettingsBloc>().add(SettingsAutoPlayChanged(val)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

// ── F14-03: Notification Section ──────────────────────────────────────────────

class _NotificationSection extends StatelessWidget {
  final SettingsState state;
  const _NotificationSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hourStr = state.notificationHour.toString().padLeft(2, '0');

    return _SettingsCard(
      children: [
        SwitchListTile(
          secondary: Icon(
            state.notificationsEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: state.notificationsEnabled
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.4),
            size: 22,
          ),
          title: Text('Hatırlatma Bildirimleri',
              style: GoogleFonts.inter(fontSize: 14)),
          subtitle: Text(
            state.notificationsEnabled
                ? 'Günlük çalışma hatırlatması'
                : 'Bildirimler kapalı',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.5)),
          ),
          value: state.notificationsEnabled,
          activeColor: scheme.primary,
          onChanged: (val) => context
              .read<SettingsBloc>()
              .add(SettingsNotificationsChanged(val)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        if (state.notificationsEnabled) ...[
          _Divider(),
          ListTile(
            leading: Icon(Icons.access_time_rounded,
                size: 22,
                color: scheme.onSurface.withValues(alpha: 0.6)),
            title: Text('Hatırlatma Saati',
                style: GoogleFonts.inter(fontSize: 14)),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$hourStr:00',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: state.notificationHour, minute: 0),
                helpText: 'Hatırlatma saatini seç',
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(ctx)
                      .copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (picked != null && context.mounted) {
                context
                    .read<SettingsBloc>()
                    .add(SettingsNotificationHourChanged(picked.hour));
              }
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ],
      ],
    );
  }
}

// ── F14-05: Clear Cache Tile ───────────────────────────────────────────────────

class _ClearCacheTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.delete_sweep_rounded,
          size: 22, color: scheme.error),
      title: Text('Lokal Verileri Temizle',
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: scheme.error)),
      subtitle: Text('İlerleme ve oturum geçmişi silinir',
          style: GoogleFonts.inter(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.5))),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Lokal Verileri Temizle',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: Text(
              'Tüm ilerleme verilerin, oturum geçmişin ve günlük planlar silinecek.\n\n'
              'Kelime veritabanı ve ayarlar korunacak.\n\n'
              'Bu işlem geri alınamaz.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('İptal',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: scheme.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Temizle',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await getIt<FirebaseAuthService>().clearUserData();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lokal veriler temizlendi',
                    style: GoogleFonts.inter()),
                backgroundColor: scheme.primary,
              ),
            );
          }
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ── F14-06: Feedback Tile ──────────────────────────────────────────────────────

class _FeedbackTile extends StatelessWidget {
  static const _supportEmail = 'support@provocabai.com';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.email_rounded,
          size: 22, color: scheme.onSurface.withValues(alpha: 0.6)),
      title: Text('Geri Bildirim Gönder',
          style: GoogleFonts.inter(fontSize: 14)),
      subtitle: Text(_supportEmail,
          style: GoogleFonts.inter(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.5))),
      trailing:
          Icon(Icons.copy_rounded, size: 18, color: scheme.primary),
      onTap: () async {
        await Clipboard.setData(
            const ClipboardData(text: _supportEmail));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('E-posta kopyalandı',
                  style: GoogleFonts.inter()),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ── F14-04: About Tile ─────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.info_outline_rounded,
          size: 22, color: scheme.onSurface.withValues(alpha: 0.6)),
      title: Text('ProVocabAI Hakkında',
          style: GoogleFonts.inter(fontSize: 14)),
      subtitle: Text('Sürüm 1.0.0',
          style: GoogleFonts.inter(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.5))),
      onTap: () => showAboutDialog(
        context: context,
        applicationName: 'ProVocabAI',
        applicationVersion: '1.0.0',
        applicationLegalese: '© 2026 ProVocabAI. Tüm hakları saklıdır.',
        children: [
          const SizedBox(height: 12),
          Text(
            'Akıllı kelime öğrenme uygulaması. '
            'FSRS-4.5 algoritması ile kişiselleştirilmiş tekrar planları.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _LicensesTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.gavel_rounded,
          size: 22, color: scheme.onSurface.withValues(alpha: 0.6)),
      title: Text('Açık Kaynak Lisansları',
          style: GoogleFonts.inter(fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: scheme.onSurface.withValues(alpha: 0.4)),
      onTap: () => showLicensePage(
        context: context,
        applicationName: 'ProVocabAI',
        applicationVersion: '1.0.0',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ── F14-02: Delete Account Tile ───────────────────────────────────────────────

class _DeleteAccountTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.person_remove_rounded,
          size: 22, color: scheme.error),
      title: Text('Hesabı Sil',
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: scheme.error)),
      subtitle: Text(
          'Tüm veriler ve hesap kalıcı olarak silinir',
          style: GoogleFonts.inter(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.5))),
      onTap: () => _confirmDeleteAccount(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;

    // İlk onay
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hesabı Sil',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Bu işlem geri alınamaz.\n\n'
          '• Tüm ilerleme verilerин silinecek\n'
          '• Firestore profil verilerин silinecek\n'
          '• Firebase hesabın silinecek\n\n'
          'Devam etmek istediğine emin misin?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Vazgeç',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Evet, Sil',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (step1 != true || !context.mounted) return;

    // Hesap silme işlemi
    try {
      await getIt<FirebaseAuthService>().deleteAccount();
      // AuthBloc auth state changes stream'i zaten dinliyor → otomatik çıkış
      if (context.mounted) {
        context.read<AuthBloc>().add(const SignOutRequested());
      }
    } on Exception catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().contains('requires-recent-login')
          ? 'Güvenlik için tekrar giriş yapman gerekiyor. Lütfen çıkış yapıp tekrar giriş yaptıktan sonra hesabını sil.'
          : 'Bir hata oluştu: $e';
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Hata',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text(msg, style: GoogleFonts.inter(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tamam',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }
}
