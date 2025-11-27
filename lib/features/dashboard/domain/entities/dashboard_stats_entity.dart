import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  final int todayQuestions;
  final double todaySuccessRate;
  final int weekQuestions;
  final double weekSuccessRate;
  final int monthQuestions;
  final double monthSuccessRate;
  final int masteredWords;
  final Map<String, int> tierDistribution;

  const DashboardStatsEntity({
    this.todayQuestions = 0,
    this.todaySuccessRate = 0.0,
    this.weekQuestions = 0,
    this.weekSuccessRate = 0.0,
    this.monthQuestions = 0,
    this.monthSuccessRate = 0.0,
    this.masteredWords = 0,
    this.tierDistribution = const {},
  });

  @override
  List<Object?> get props => [todayQuestions, weekQuestions, masteredWords];
}
