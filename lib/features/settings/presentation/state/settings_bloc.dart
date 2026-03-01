// lib/features/settings/presentation/state/settings_bloc.dart
//
// FAZ 6 FIX — Bildirim ayarı:
//   - SettingsNotificationsChanged event
//   - notificationsEnabled state alanı
//   - _onNotifications handler

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/domain/repositories/i_settings_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

class SettingsSourceLangChanged extends SettingsEvent {
  final String lang;
  const SettingsSourceLangChanged(this.lang);
  @override
  List<Object?> get props => [lang];
}

class SettingsTargetLangChanged extends SettingsEvent {
  final String lang;
  const SettingsTargetLangChanged(this.lang);
  @override
  List<Object?> get props => [lang];
}

class SettingsProficiencyChanged extends SettingsEvent {
  final String level;
  const SettingsProficiencyChanged(this.level);
  @override
  List<Object?> get props => [level];
}

class SettingsDailyGoalChanged extends SettingsEvent {
  final int goal;
  const SettingsDailyGoalChanged(this.goal);
  @override
  List<Object?> get props => [goal];
}

class SettingsBatchSizeChanged extends SettingsEvent {
  final int size;
  const SettingsBatchSizeChanged(this.size);
  @override
  List<Object?> get props => [size];
}

class SettingsAutoPlayChanged extends SettingsEvent {
  final bool value;
  const SettingsAutoPlayChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class SettingsThemeModeChanged extends SettingsEvent {
  final ThemeMode mode;
  const SettingsThemeModeChanged(this.mode);
  @override
  List<Object?> get props => [mode.index];
}

/// FAZ 6: Bildirim açma/kapama
class SettingsNotificationsChanged extends SettingsEvent {
  final bool enabled;
  const SettingsNotificationsChanged(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsState extends Equatable {
  final bool isLoading;
  final String sourceLang;
  final String targetLang;
  final String proficiencyLevel;
  final int dailyGoal;
  final int batchSize;
  final bool autoPlaySound;
  final ThemeMode themeMode;
  final bool notificationsEnabled;

  const SettingsState({
    this.isLoading = true,
    this.sourceLang = 'tr',
    this.targetLang = 'en',
    this.proficiencyLevel = 'beginner',
    this.dailyGoal = 20,
    this.batchSize = 10,
    this.autoPlaySound = true,
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
  });

  SettingsState copyWith({
    bool? isLoading,
    String? sourceLang,
    String? targetLang,
    String? proficiencyLevel,
    int? dailyGoal,
    int? batchSize,
    bool? autoPlaySound,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
  }) =>
      SettingsState(
        isLoading: isLoading ?? this.isLoading,
        sourceLang: sourceLang ?? this.sourceLang,
        targetLang: targetLang ?? this.targetLang,
        proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        batchSize: batchSize ?? this.batchSize,
        autoPlaySound: autoPlaySound ?? this.autoPlaySound,
        themeMode: themeMode ?? this.themeMode,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  @override
  List<Object?> get props => [
        isLoading,
        sourceLang,
        targetLang,
        proficiencyLevel,
        dailyGoal,
        batchSize,
        autoPlaySound,
        themeMode,
        notificationsEnabled,
      ];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required ISettingsRepository settingsRepository})
      : _repo = settingsRepository,
        super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoad);
    on<SettingsSourceLangChanged>(_onSourceLang);
    on<SettingsTargetLangChanged>(_onTargetLang);
    on<SettingsProficiencyChanged>(_onProficiency);
    on<SettingsDailyGoalChanged>(_onDailyGoal);
    on<SettingsBatchSizeChanged>(_onBatchSize);
    on<SettingsAutoPlayChanged>(_onAutoPlay);
    on<SettingsThemeModeChanged>(_onThemeMode);
    on<SettingsNotificationsChanged>(_onNotifications);
  }

  final ISettingsRepository _repo;

  Future<void> _onLoad(
      SettingsLoadRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));

    final langResult = await _repo.getLanguageSettings();
    final lang = langResult.fold((_) => <String, String>{}, (v) => v);

    final dailyGoalResult = await _repo.getDailyGoal();
    final dailyGoal = dailyGoalResult.fold((_) => 20, (v) => v);

    final batchSizeResult = await _repo.getBatchSize();
    final batchSize = batchSizeResult.fold((_) => 10, (v) => v);

    final autoPlayResult = await _repo.getAutoPlaySound();
    final autoPlay = autoPlayResult.fold((_) => true, (v) => v);

    final themeModeResult = await _repo.getThemeMode();
    final themeMode = themeModeResult.fold((_) => ThemeMode.system, (v) => v);

    final notifResult = await _repo.getNotificationsEnabled();
    final notifEnabled = notifResult.fold((_) => true, (v) => v);

    emit(state.copyWith(
      isLoading: false,
      sourceLang: lang['source'] ?? 'tr',
      targetLang: lang['target'] ?? 'en',
      proficiencyLevel: lang['level'] ?? 'beginner',
      dailyGoal: dailyGoal,
      batchSize: batchSize,
      autoPlaySound: autoPlay,
      themeMode: themeMode,
      notificationsEnabled: notifEnabled,
    ));
  }

  Future<void> _onSourceLang(
      SettingsSourceLangChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(sourceLang: event.lang));
    await _repo.saveLanguageSettings(event.lang, state.targetLang);
  }

  Future<void> _onTargetLang(
      SettingsTargetLangChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(targetLang: event.lang));
    await _repo.saveLanguageSettings(state.sourceLang, event.lang);
  }

  Future<void> _onProficiency(
      SettingsProficiencyChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(proficiencyLevel: event.level));
    await _repo.saveProficiencyLevel(event.level);
  }

  Future<void> _onDailyGoal(
      SettingsDailyGoalChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(dailyGoal: event.goal));
    await _repo.saveDailyGoal(event.goal);
  }

  Future<void> _onBatchSize(
      SettingsBatchSizeChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(batchSize: event.size));
    await _repo.saveBatchSize(event.size);
  }

  Future<void> _onAutoPlay(
      SettingsAutoPlayChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(autoPlaySound: event.value));
    await _repo.saveAutoPlaySound(event.value);
  }

  Future<void> _onThemeMode(
      SettingsThemeModeChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(themeMode: event.mode));
    await _repo.saveThemeMode(event.mode);
  }

  Future<void> _onNotifications(
      SettingsNotificationsChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(notificationsEnabled: event.enabled));
    await _repo.saveNotificationsEnabled(event.enabled);
  }
}
