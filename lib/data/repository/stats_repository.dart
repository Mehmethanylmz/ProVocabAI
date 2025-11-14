import '../../core/database_helper.dart';
import '../../models/dashboard_stats.dart';
import '../../utils/spaced_repetition.dart';

class StatsRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<Map<String, int>> getTierDistribution() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        CASE
          WHEN mastery_level = ${SpacedRepetition.leechLevel} THEN 'Struggling'
          WHEN mastery_level = 0 THEN 'Unlearned'
          WHEN mastery_level BETWEEN 1 AND 3 THEN 'Novice'
          WHEN mastery_level BETWEEN 4 AND 6 THEN 'Apprentice'
          WHEN mastery_level >= 7 THEN 'Expert'
          ELSE 'Other' 
        END as tier,
        COUNT(id) as count
      FROM words
      GROUP BY tier
    ''');

    Map<String, int> distribution = {
      'Unlearned': 0,
      'Struggling': 0,
      'Novice': 0,
      'Apprentice': 0,
      'Expert': 0,
    };

    for (var map in maps) {
      final tier = map['tier'] as String?;
      final count = map['count'] as int? ?? 0;

      if (tier != null && distribution.containsKey(tier)) {
        distribution[tier] = count;
      }
    }
    return distribution;
  }

  Future<DashboardStats> getDashboardStats() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final startOfWeek = now
        .subtract(Duration(days: now.weekday - 1))
        .millisecondsSinceEpoch;
    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    ).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(id) FROM words WHERE mastery_level >= ${SpacedRepetition.maxLevel}) as masteredWords,
        
        (SELECT SUM(totalCount) FROM test_results 
         WHERE timestamp >= $startOfDay) as todayQuestions,
        (SELECT (CAST(SUM(correctCount) AS REAL) / SUM(totalCount)) * 100 
         FROM test_results WHERE timestamp >= $startOfDay) as todaySuccessRate,
         
        (SELECT SUM(totalCount) FROM test_results 
         WHERE timestamp >= $startOfWeek) as weekQuestions,
        (SELECT (CAST(SUM(correctCount) AS REAL) / SUM(totalCount)) * 100 
         FROM test_results WHERE timestamp >= $startOfWeek) as weekSuccessRate,
         
        (SELECT SUM(totalCount) FROM test_results 
         WHERE timestamp >= $startOfMonth) as monthQuestions,
        (SELECT (CAST(SUM(correctCount) AS REAL) / SUM(totalCount)) * 100 
         FROM test_results WHERE timestamp >= $startOfMonth) as monthSuccessRate
    ''');

    final tierDistribution = await getTierDistribution();

    if (results.isEmpty) {
      return DashboardStats(tierDistribution: tierDistribution);
    }

    final data = results.first.map((key, value) => MapEntry(key, value));
    data['tierDistribution'] = tierDistribution;

    return DashboardStats.fromMap(data);
  }

  Future<void> takeProgressSnapshot() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final todayEpoch = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;

    final existing = await db.query(
      'progress_snapshots',
      where: 'date = ?',
      whereArgs: [todayEpoch],
    );

    final distribution = await getTierDistribution();

    final snapshotData = {
      'date': todayEpoch,
      'unlearned': distribution['Unlearned'] ?? 0,
      'struggling': distribution['Struggling'] ?? 0,
      'novice': distribution['Novice'] ?? 0,
      'apprentice': distribution['Apprentice'] ?? 0,
      'expert': distribution['Expert'] ?? 0,
    };

    if (existing.isEmpty) {
      await db.insert('progress_snapshots', snapshotData);
    } else {
      await db.update(
        'progress_snapshots',
        snapshotData,
        where: 'date = ?',
        whereArgs: [todayEpoch],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyActivityStats() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', timestamp / 1000, 'unixepoch') as monthYear,
        SUM(totalCount) as total,
        SUM(correctCount) as correct
      FROM test_results
      GROUP BY monthYear
      ORDER BY monthYear DESC
    ''');
    return results;
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivityStatsForMonth(
    String monthYear,
  ) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT 
        strftime('%W', timestamp / 1000, 'unixepoch') as weekOfYear,
        SUM(totalCount) as total,
        SUM(correctCount) as correct,
        MIN(timestamp / 1000, 'unixepoch') as weekStartDate
      FROM test_results
      WHERE strftime('%Y-%m', timestamp / 1000, 'unixepoch') = ?
      GROUP BY weekOfYear
      ORDER BY weekStartDate ASC
    ''',
      [monthYear],
    );
    return results;
  }

  Future<List<Map<String, dynamic>>> getDailyActivityStatsForWeek(
    String weekOfYear,
    String year,
  ) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT 
        strftime('%w', timestamp / 1000, 'unixepoch') as dayOfWeek,
        SUM(totalCount) as total,
        SUM(correctCount) as correct,
        date(timestamp / 1000, 'unixepoch') as fullDate
      FROM test_results
      WHERE strftime('%Y', timestamp / 1000, 'unixepoch') = ?
        AND strftime('%W', timestamp / 1000, 'unixepoch') = ?
      GROUP BY dayOfWeek
      ORDER BY fullDate ASC
    ''',
      [year, weekOfYear],
    );

    final dayNames = [
      'Pazar',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
    ];
    List<Map<String, dynamic>> formattedResults = [];

    for (var res in results) {
      final dayIndex = int.parse(res['dayOfWeek'] as String);
      formattedResults.add({
        'dayName': dayNames[dayIndex],
        'fullDate': res['fullDate'],
        'total': res['total'],
        'correct': res['correct'],
      });
    }
    return formattedResults;
  }

  Future<Map<String, dynamic>> getProgressForMonth(String monthYear) async {
    final db = await dbHelper.database;
    final parts = monthYear.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final startOfMonthEpoch = DateTime(year, month, 1).millisecondsSinceEpoch;
    final endOfMonthEpoch = DateTime(year, month + 1, 0).millisecondsSinceEpoch;

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
      return {};
    }

    return {'start': startSnapshot.first, 'end': endSnapshot.first};
  }
}
