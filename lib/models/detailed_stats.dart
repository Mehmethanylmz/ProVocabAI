// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\models\detailed_stats.dart

class ChartDataPoint {
  final String label;
  final double value;

  ChartDataPoint(this.label, this.value);
}

class ActivityStats {
  final int testCount;
  final int totalEfor;
  final int correctCount;
  final double successRate;

  ActivityStats({
    this.testCount = 0,
    this.totalEfor = 0,
    this.correctCount = 0,
    this.successRate = 0.0,
  });

  factory ActivityStats.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) return ActivityStats();
    final int total = map['totalEfor'] ?? 0;
    final int correct = map['correctCount'] ?? 0;
    return ActivityStats(
      testCount: map['testCount'] ?? 0,
      totalEfor: total,
      correctCount: correct,
      successRate: (total == 0) ? 0.0 : (correct / total) * 100,
    );
  }
}

class DetailedStats {
  final int dailyStreak;
  final ActivityStats todayStats;
  final ActivityStats weekStats;
  final ActivityStats monthStats;
  final ActivityStats allTimeStats;
  final List<ChartDataPoint> weeklySuccessChart;
  final Map<String, int> masteryDistribution;
  final Map<String, int> hazineStats;

  DetailedStats({
    required this.dailyStreak,
    required this.todayStats,
    required this.weekStats,
    required this.monthStats,
    required this.allTimeStats,
    required this.weeklySuccessChart,
    required this.masteryDistribution,
    required this.hazineStats,
  });
}
