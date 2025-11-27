import '../../domain/entities/test_result_entity.dart';

class TestResultModel extends TestResultEntity {
  const TestResultModel({
    required super.date,
    required super.questions,
    required super.correct,
    required super.wrong,
    required super.duration,
    required super.successRate,
  });

  factory TestResultModel.fromMap(Map<String, dynamic> map) {
    return TestResultModel(
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
