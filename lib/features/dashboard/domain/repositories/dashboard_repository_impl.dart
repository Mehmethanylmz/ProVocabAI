import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/error/failures.dart';
import '../../../../product/init/database/ProductDatabaseManager.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  final ProductDatabaseManager _dbManager;

  DashboardRepositoryImpl(this._dbManager);

  // Yardımcı: Yerel saat farkını saniye cinsinden al
  int get _offsetInSeconds => DateTime.now().timeZoneOffset.inSeconds;

  @override
  Future<Either<Failure, DashboardStatsEntity>> getDashboardStats(
      String targetLang) async {
    try {
      final db = await _dbManager.database;
      final now = DateTime.now();

      final startOfDay =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final startOfWeek =
          now.subtract(Duration(days: now.weekday - 1)).millisecondsSinceEpoch;
      final startOfMonth =
          DateTime(now.year, now.month, 1).millisecondsSinceEpoch;

      final masteredCount = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM progress WHERE target_lang = ? AND mastery_level >= 4',
              [targetLang],
            ),
          ) ??
          0;

      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT 
          (SELECT SUM(totalCount) FROM test_results WHERE timestamp >= $startOfDay) as todayQuestions,
          (SELECT (CAST(SUM(correctCount) AS REAL) / SUM(totalCount)) * 100 FROM test_results WHERE timestamp >= $startOfDay) as todaySuccessRate,
          (SELECT SUM(totalCount) FROM test_results WHERE timestamp >= $startOfWeek) as weekQuestions,
          (SELECT (CAST(SUM(correctCount) AS REAL) / SUM(totalCount)) * 100 FROM test_results WHERE timestamp >= $startOfWeek) as weekSuccessRate,
          (SELECT SUM(totalCount) FROM test_results WHERE timestamp >= $startOfMonth) as monthQuestions,
          (SELECT (CAST(SUM(correctCount) AS REAL) / SUM(totalCount)) * 100 FROM test_results WHERE timestamp >= $startOfMonth) as monthSuccessRate
      ''');

      final tierDistribution = await _getTierDistribution(db, targetLang);

      if (results.isEmpty) {
        return Right(DashboardStatsModel(
          tierDistribution: tierDistribution,
          masteredWords: masteredCount,
        ));
      }

      // Sqflite'dan dönen Map read-only olabilir, kopyasını alalım
      final data = Map<String, dynamic>.from(results.first);

      // Null değerleri 0 ile değiştirelim ki Model patlamasın
      data['todayQuestions'] ??= 0;
      data['todaySuccessRate'] ??= 0.0;
      data['weekQuestions'] ??= 0;
      data['weekSuccessRate'] ??= 0.0;
      data['monthQuestions'] ??= 0;
      data['monthSuccessRate'] ??= 0.0;

      data['tierDistribution'] = tierDistribution;
      data['masteredWords'] = masteredCount;

      return Right(DashboardStatsModel.fromMap(data));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getMonthlyActivityStats() async {
    try {
      final db = await _dbManager.database;
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT 
          strftime('%Y-%m', (timestamp / 1000) + ?, 'unixepoch') as monthYear,
          SUM(totalCount) as total,
          SUM(correctCount) as correct
        FROM test_results
        GROUP BY monthYear
        ORDER BY monthYear DESC
      ''', [_offsetInSeconds]);
      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getWeeklyActivityStatsForMonth(String monthYear) async {
    try {
      final db = await _dbManager.database;
      final List<Map<String, dynamic>> results = await db.rawQuery(
        '''
        SELECT 
          strftime('%W', (timestamp / 1000) + ?, 'unixepoch') as weekOfYear,
          SUM(totalCount) as total,
          SUM(correctCount) as correct,
          MIN((timestamp / 1000) + ?, 'unixepoch') as weekStartDate
        FROM test_results
        WHERE strftime('%Y-%m', (timestamp / 1000) + ?, 'unixepoch') = ?
        GROUP BY weekOfYear
        ORDER BY weekStartDate ASC
      ''',
        [_offsetInSeconds, _offsetInSeconds, _offsetInSeconds, monthYear],
      );
      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getDailyActivityStatsForWeek(String weekOfYear, String year) async {
    try {
      final db = await _dbManager.database;
      final List<Map<String, dynamic>> results = await db.rawQuery(
        '''
        SELECT 
          strftime('%w', (timestamp / 1000) + ?, 'unixepoch') as dayOfWeek,
          strftime('%d-%m-%Y', (timestamp / 1000) + ?, 'unixepoch') as dateStr,
          SUM(totalCount) as total,
          SUM(correctCount) as correct
        FROM test_results
        WHERE strftime('%Y', (timestamp / 1000) + ?, 'unixepoch') = ?
          AND strftime('%W', (timestamp / 1000) + ?, 'unixepoch') = ?
        GROUP BY dateStr
        ORDER BY dateStr ASC
      ''',
        [
          _offsetInSeconds,
          _offsetInSeconds,
          _offsetInSeconds,
          year,
          _offsetInSeconds,
          weekOfYear
        ],
      );

      final formattedResults = results.map((row) {
        final dateStr = row['dateStr'] as String;
        final parts = dateStr.split('-');
        final date = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );

        return {
          'weekday': row['dayOfWeek'],
          'date': date.millisecondsSinceEpoch ~/ 1000,
          'total': row['total'],
          'correct': row['correct'],
        };
      }).toList();

      return Right(formattedResults);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProgressForMonth(
      String monthYear) async {
    try {
      final db = await _dbManager.database;
      final parts = monthYear.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      final startOfMonthEpoch = DateTime(year, month, 1).millisecondsSinceEpoch;
      final endOfMonthEpoch =
          DateTime(year, month + 1, 0).millisecondsSinceEpoch;

      final startSnapshot = await db.query(
        'progress_snapshots',
        orderBy: 'date ASC',
        where: 'date >= ?',
        whereArgs: [startOfMonthEpoch],
        limit: 1,
      );

      final endSnapshot = await db.query(
        'progress_snapshots',
        orderBy: 'date DESC',
        where: 'date <= ?',
        whereArgs: [endOfMonthEpoch],
        limit: 1,
      );

      if (startSnapshot.isEmpty || endSnapshot.isEmpty) {
        return const Right({});
      }

      return Right({'start': startSnapshot.first, 'end': endSnapshot.first});
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Future<Map<String, int>> _getTierDistribution(
      Database db, String targetLang) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        CASE
          WHEN mastery_level = -1 THEN 'Struggling'
          WHEN mastery_level = 0 THEN 'Unlearned'
          WHEN mastery_level BETWEEN 1 AND 3 THEN 'Novice'
          WHEN mastery_level BETWEEN 4 AND 6 THEN 'Apprentice'
          WHEN mastery_level >= 7 THEN 'Expert'
          ELSE 'Other' 
        END as tier,
        COUNT(word_id) as count
      FROM progress
      WHERE target_lang = ?
      GROUP BY tier
    ''', [targetLang]);

    final int totalWords = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM words'),
        ) ??
        0;
    final int activeWords = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM progress WHERE target_lang = ?',
            [targetLang],
          ),
        ) ??
        0;

    Map<String, int> distribution = {
      'Unlearned': totalWords - activeWords,
      'Struggling': 0,
      'Novice': 0,
      'Apprentice': 0,
      'Expert': 0,
    };

    final unlearnedInProgress = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM progress WHERE target_lang = ? AND mastery_level = 0',
            [targetLang],
          ),
        ) ??
        0;

    distribution['Unlearned'] =
        (distribution['Unlearned'] ?? 0) + unlearnedInProgress;

    for (var map in maps) {
      final tier = map['tier'] as String?;
      final count = map['count'] as int? ?? 0;
      if (tier != null &&
          tier != 'Unlearned' &&
          distribution.containsKey(tier)) {
        distribution[tier] = count;
      }
    }
    return distribution;
  }
}
