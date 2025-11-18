class TestResult {
  final DateTime date;
  final int questions;
  final int correct;
  final int wrong;
  final Duration duration;
  final double successRate;

  TestResult({
    required this.date,
    required this.questions,
    required this.correct,
    required this.wrong,
    required this.duration,
    required this.successRate,
  });

  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      date: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      questions: map['totalCount'],
      correct: map['correctCount'],
      wrong: map['totalCount'] - map['correctCount'],
      duration: Duration(seconds: map['durationSeconds'] ?? 0),
      successRate: (map['successRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': date.millisecondsSinceEpoch,
      'totalCount': questions,
      'correctCount': correct,
      'durationSeconds': duration.inSeconds,
      'successRate': successRate,
    };
  }
}
