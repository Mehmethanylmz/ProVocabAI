import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_stats_entity.dart';

abstract class IDashboardRepository {
  Future<Either<Failure, DashboardStatsEntity>> getDashboardStats(
      String targetLang);
  Future<Either<Failure, List<Map<String, dynamic>>>> getMonthlyActivityStats();
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getWeeklyActivityStatsForMonth(String monthYear);
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getDailyActivityStatsForWeek(String weekOfYear, String year);
  Future<Either<Failure, Map<String, dynamic>>> getProgressForMonth(
      String monthYear);
}
