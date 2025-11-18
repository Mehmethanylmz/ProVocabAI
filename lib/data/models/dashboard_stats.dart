class DashboardStats {
  final int todayQuestions;
  final double todaySuccessRate;
  final int weekQuestions;
  final double weekSuccessRate;
  final int monthQuestions;
  final double monthSuccessRate;
  final int masteredWords;
  final Map<String, int> tierDistribution;

  DashboardStats({
    this.todayQuestions = 0,
    this.todaySuccessRate = 0.0,
    this.weekQuestions = 0,
    this.weekSuccessRate = 0.0,
    this.monthQuestions = 0,
    this.monthSuccessRate = 0.0,
    this.masteredWords = 0,
    this.tierDistribution = const {},
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      todayQuestions: map['todayQuestions'] as int? ?? 0,
      todaySuccessRate: (map['todaySuccessRate'] as num?)?.toDouble() ?? 0.0,
      weekQuestions: map['weekQuestions'] as int? ?? 0,
      weekSuccessRate: (map['weekSuccessRate'] as num?)?.toDouble() ?? 0.0,
      monthQuestions: map['monthQuestions'] as int? ?? 0,
      monthSuccessRate: (map['monthSuccessRate'] as num?)?.toDouble() ?? 0.0,
      masteredWords: map['masteredWords'] as int? ?? 0,
      tierDistribution: map['tierDistribution'] as Map<String, int>? ?? {},
    );
  }
}
