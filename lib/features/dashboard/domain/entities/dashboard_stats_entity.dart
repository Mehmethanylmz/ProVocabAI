// lib/features/dashboard/domain/entities/dashboard_stats_entity.dart
//
// FAZ 12 — F12-01: DashboardStatsEntity genişletme
//   - Detaylı doğru/yanlış/süre metrikleri (bugün, hafta, ay)
//   - todayModeDistribution: Bugünkü mod dağılımı
//   - heatmapData: Son 26 haftanın günlük aktivite listesi

import 'package:equatable/equatable.dart';

/// Belirli bir günün aktivitesi — ısı haritası (heatmap) ve takvim için.
class DayActivity {
  final String date; // 'yyyy-MM-dd' formatında
  final int questionCount;
  final int correctCount;
  final int timeMinutes;

  const DayActivity({
    required this.date,
    required this.questionCount,
    this.correctCount = 0,
    this.timeMinutes = 0,
  });

  int get wrongCount => questionCount - correctCount;

  double get successRate =>
      questionCount > 0 ? correctCount / questionCount * 100 : 0.0;
}

class DashboardStatsEntity extends Equatable {
  // ── Mevcut alanlar ──────────────────────────────────────────────────────────
  final int todayQuestions;
  final double todaySuccessRate;
  final int weekQuestions;
  final double weekSuccessRate;
  final int monthQuestions;
  final double monthSuccessRate;
  final int masteredWords;
  final Map<String, int> tierDistribution;

  // ── YENİ: Detaylı metrikler (F12-01) ────────────────────────────────────────
  final int todayCorrect;
  final int todayWrong;
  final int todayTimeMinutes;

  final int weekCorrect;
  final int weekWrong;
  final int weekTimeMinutes;

  final int monthCorrect;
  final int monthWrong;

  /// Bugünkü mod dağılımı: {'mcq': 12, 'listening': 5, 'speaking': 3}
  final Map<String, int> todayModeDistribution;

  /// Son 26 haftanın (182 gün) günlük aktivite verisi — ısı haritası için.
  final List<DayActivity> heatmapData;

  const DashboardStatsEntity({
    this.todayQuestions = 0,
    this.todaySuccessRate = 0.0,
    this.weekQuestions = 0,
    this.weekSuccessRate = 0.0,
    this.monthQuestions = 0,
    this.monthSuccessRate = 0.0,
    this.masteredWords = 0,
    this.tierDistribution = const {},
    // New
    this.todayCorrect = 0,
    this.todayWrong = 0,
    this.todayTimeMinutes = 0,
    this.weekCorrect = 0,
    this.weekWrong = 0,
    this.weekTimeMinutes = 0,
    this.monthCorrect = 0,
    this.monthWrong = 0,
    this.todayModeDistribution = const {},
    this.heatmapData = const [],
  });

  @override
  List<Object?> get props => [
        todayQuestions,
        weekQuestions,
        masteredWords,
        heatmapData.length,
        todayModeDistribution,
      ];
}
