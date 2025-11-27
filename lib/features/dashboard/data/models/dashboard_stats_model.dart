import '../../domain/entities/dashboard_stats_entity.dart';

class DashboardStatsModel extends DashboardStatsEntity {
  const DashboardStatsModel({
    super.todayQuestions,
    super.todaySuccessRate,
    super.weekQuestions,
    super.weekSuccessRate,
    super.monthQuestions,
    super.monthSuccessRate,
    super.masteredWords,
    super.tierDistribution,
  });

  factory DashboardStatsModel.fromMap(Map<String, dynamic> map) {
    return DashboardStatsModel(
      todayQuestions: map['todayQuestions'] as int? ?? 0,
      todaySuccessRate: (map['todaySuccessRate'] as num?)?.toDouble() ?? 0.0,
      weekQuestions: map['weekQuestions'] as int? ?? 0,
      weekSuccessRate: (map['weekSuccessRate'] as num?)?.toDouble() ?? 0.0,
      monthQuestions: map['monthQuestions'] as int? ?? 0,
      monthSuccessRate: (map['monthSuccessRate'] as num?)?.toDouble() ?? 0.0,
      masteredWords: map['masteredWords'] as int? ?? 0,
      tierDistribution: (map['tierDistribution'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
    );
  }
}
