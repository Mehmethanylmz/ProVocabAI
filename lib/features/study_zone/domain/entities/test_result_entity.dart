import 'package:equatable/equatable.dart';

class TestResultEntity extends Equatable {
  final DateTime date;
  final int questions;
  final int correct;
  final int wrong;
  final Duration duration;
  final double successRate;

  const TestResultEntity({
    required this.date,
    required this.questions,
    required this.correct,
    required this.wrong,
    required this.duration,
    required this.successRate,
  });

  @override
  List<Object?> get props =>
      [date, questions, correct, wrong, duration, successRate];
}
