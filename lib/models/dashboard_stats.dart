class DashboardStats {
  final int wordsLearnedToday;
  final int wordsLearnedThisWeek;
  final double overallSuccessRate;
  final int totalLearnedWords;

  DashboardStats({
    this.wordsLearnedToday = 0,
    this.wordsLearnedThisWeek = 0,
    this.overallSuccessRate = 0.0,
    this.totalLearnedWords = 0,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      wordsLearnedToday: map['wordsLearnedToday'] as int? ?? 0,
      wordsLearnedThisWeek: map['wordsLearnedThisWeek'] as int? ?? 0,
      overallSuccessRate:
          (map['overallSuccessRate'] as num?)?.toDouble() ?? 0.0,
      totalLearnedWords: map['totalLearnedWords'] as int? ?? 0,
    );
  }
}
