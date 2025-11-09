// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\models\dashboard_stats.dart

class DashboardStats {
  final int todayEfor;
  final double todaySuccessRate;
  final int totalLearnedWords;

  DashboardStats({
    this.todayEfor = 0,
    this.todaySuccessRate = 0.0,
    this.totalLearnedWords = 0,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      todayEfor: map['todayEfor'] as int? ?? 0,
      todaySuccessRate: (map['todaySuccessRate'] as num?)?.toDouble() ?? 0.0,
      totalLearnedWords: map['totalLearnedWords'] as int? ?? 0,
    );
  }
}
