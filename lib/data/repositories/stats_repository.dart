import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../../utils/spaced_repetition.dart';
import '../models/dashboard_stats.dart';

class StatsRepository {
  final dbHelper = DatabaseHelper.instance;

  // Yardımcı: Yerel saat farkını saniye cinsinden al (Örn: TR için +10800)
  int get _offsetInSeconds => DateTime.now().timeZoneOffset.inSeconds;

  Future<Map<String, int>> getTierDistribution(String targetLang) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        CASE
          WHEN mastery_level = ${SpacedRepetition.leechLevel} THEN 'Struggling'
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
    ''',
      [targetLang],
    );

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

  Future<DashboardStats> getDashboardStats(String targetLang) async {
    final db = await dbHelper.database;
    final now = DateTime.now();

    // Yerel saat ile gün, hafta ve ay başlangıçlarını alıyoruz.
    // timestamp DB'de UTC tutuluyor olsa bile, DateTime(...).millisecondsSinceEpoch
    // yerel saatin o anki UTC karşılığını verir.
    // Örnek: TR saatiyle gece 00:00 aslında UTC 21:00'dır.
    // Bu hesaplama doğrudur, çünkü DB'deki timestamp >= UTC 21:00 dediğimizde
    // aslında yerel saatle 00:00'dan sonrasını kastetmiş oluruz.

    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final startOfWeek = now
        .subtract(Duration(days: now.weekday - 1))
        .millisecondsSinceEpoch; // Pazartesi

    // Ay başı hesabı (Düzeltme: Sadece yıl ve ay vererek o ayın 1. günü 00:00 alınır)
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

    final tierDistribution = await getTierDistribution(targetLang);

    if (results.isEmpty) {
      return DashboardStats(
        tierDistribution: tierDistribution,
        masteredWords: masteredCount,
      );
    }

    final data = results.first.map((key, value) => MapEntry(key, value));
    data['tierDistribution'] = tierDistribution;
    data['masteredWords'] = masteredCount;

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

    final distribution = await getTierDistribution('tr');

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

  // --- DÜZELTİLEN METOTLAR (SAAT DİLİMİ AYARLI) ---

  Future<List<Map<String, dynamic>>> getMonthlyActivityStats() async {
    final db = await dbHelper.database;
    // timestamp ms cinsinden, 1000'e bölüp saniye yapıyoruz.
    // Sonra yerel saat farkını (offset) ekliyoruz.
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', (timestamp / 1000) + ?, 'unixepoch') as monthYear,
        SUM(totalCount) as total,
        SUM(correctCount) as correct
      FROM test_results
      GROUP BY monthYear
      ORDER BY monthYear DESC
    ''', [_offsetInSeconds]);
    return results;
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivityStatsForMonth(
    String monthYear,
  ) async {
    final db = await dbHelper.database;
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
    return results;
  }

  Future<List<Map<String, dynamic>>> getDailyActivityStatsForWeek(
    String weekOfYear,
    String year,
  ) async {
    final db = await dbHelper.database;

    // Günlük verileri çekerken de yerel saati baz alıyoruz.
    // dateStr (dd-MM-yyyy) formatında grupluyoruz ki gece yarısı geçişleri düzgün olsun.
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

    // Sonuçları UI'ın beklediği formata dönüştür
    return results.map((row) {
      final dateStr = row['dateStr'] as String;
      final parts = dateStr.split('-');
      // String tarihi DateTime objesine çevirip saniye timestamp'ini alıyoruz
      final date = DateTime(
        int.parse(parts[2]), // Yıl
        int.parse(parts[1]), // Ay
        int.parse(parts[0]), // Gün
      );

      return {
        'weekday': row['dayOfWeek'],
        // ActivityHistoryList widget'ı "date" alanını integer (saniye) olarak bekliyor
        'date': date.millisecondsSinceEpoch ~/ 1000,
        'total': row['total'],
        'correct': row['correct'],
      };
    }).toList();
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
