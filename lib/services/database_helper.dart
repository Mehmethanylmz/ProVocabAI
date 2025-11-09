// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\services\database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/word_model.dart';
import '../models/dashboard_stats.dart';
import '../models/detailed_stats.dart';
import '../utils/spaced_repetition.dart';
import 'dart:math';

class BatchHistory {
  final int batchId;
  final int wordCount;
  final double? lastScore;
  final double? bestScore;

  BatchHistory({
    required this.batchId,
    required this.wordCount,
    this.lastScore,
    this.bestScore,
  });
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _userWordIdThreshold = 1000000;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('words.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE words ( 
  id INTEGER PRIMARY KEY, 
  en TEXT NOT NULL,
  tr TEXT NOT NULL,
  meaning TEXT,
  example_sentence TEXT,
  notes TEXT,
  status TEXT NOT NULL,
  batchId INTEGER DEFAULT NULL,
  mastery_level INTEGER DEFAULT 0 NOT NULL,
  review_due_date INTEGER DEFAULT 0 NOT NULL,
  wrong_streak INTEGER DEFAULT 0 NOT NULL
)
''');
    await db.execute('''
CREATE TABLE batch_scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batchId INTEGER NOT NULL,
  correctCount INTEGER NOT NULL,
  totalCount INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  is_new_session INTEGER DEFAULT 0 NOT NULL
)
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE batch_scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  batchId INTEGER NOT NULL,
  correctCount INTEGER NOT NULL,
  totalCount INTEGER NOT NULL,
  timestamp INTEGER NOT NULL
)
''');
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE words ADD COLUMN mastery_level INTEGER DEFAULT 0 NOT NULL",
      );
      await db.execute(
        "ALTER TABLE words ADD COLUMN review_due_date INTEGER DEFAULT 0 NOT NULL",
      );
      await db.execute(
        "ALTER TABLE words ADD COLUMN wrong_streak INTEGER DEFAULT 0 NOT NULL",
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE batch_scores ADD COLUMN is_new_session INTEGER DEFAULT 0 NOT NULL",
      );
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE words ADD COLUMN notes TEXT");

      final List<Map<String, dynamic>> maps = await db.query('words');
      final batch = db.batch();
      for (var map in maps) {
        String oldSentence = map['example_sentence'] ?? '';
        if (oldSentence.isNotEmpty && !oldSentence.startsWith('[')) {
          String newSentenceJson = jsonEncode([oldSentence]);
          batch.update(
            'words',
            {'example_sentence': newSentenceJson},
            where: 'id = ?',
            whereArgs: [map['id']],
          );
        }
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> populateDatabase() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words'),
    );
    if (count != null && count > 0) {
      return;
    }
    final String response = await rootBundle.loadString('assets/words.json');
    final List<dynamic> data = json.decode(response);
    Batch batch = db.batch();
    for (var item in data) {
      String example = item['example_sentence'] ?? '';
      Map<String, dynamic> wordMap = {
        'id': item['id'],
        'en': item['en'],
        'tr': item['tr'],
        'meaning': item['meaning'],
        'example_sentence': jsonEncode(example.isNotEmpty ? [example] : []),
        'notes': '',
        'status': 'unseen',
        'mastery_level': 0,
        'review_due_date': 0,
        'wrong_streak': 0,
      };
      batch.insert(
        'words',
        wordMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.apply();
  }

  Future<void> insertWord(Word word) async {
    final db = await database;
    await db.insert(
      'words',
      word.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteWord(int id) async {
    final db = await database;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Word>> getUserWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'id > ?',
      whereArgs: [_userWordIdThreshold],
      orderBy: 'en ASC',
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<void> insertBatchScore(
    int batchId,
    int correct,
    int total,
    bool isNewSession,
  ) async {
    final db = await database;
    await db.insert('batch_scores', {
      'batchId': batchId,
      'correctCount': correct,
      'totalCount': total,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'is_new_session': isNewSession ? 1 : 0,
    });
  }

  Future<DashboardStats> getDashboardStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(id) FROM words WHERE mastery_level > 0) as totalLearnedWords,
        
        (SELECT SUM(totalCount) FROM batch_scores 
         WHERE timestamp >= $startOfDay) as todayEfor,
         
        (SELECT (CAST(SUM(correctCount) AS REAL) / SUM(totalCount)) * 100 
         FROM batch_scores
         WHERE timestamp >= $startOfDay) as todaySuccessRate
    ''');

    if (results.isEmpty) {
      return DashboardStats();
    }
    return DashboardStats.fromMap(results.first);
  }

  Future<List<int>> getWeeklyEffort() async {
    final db = await database;
    List<int> weeklyEffort = List.filled(7, 0);
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final startDate = todayMidnight.subtract(Duration(days: 6));
    final startTimeStamp = startDate.millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        SUM(totalCount) as count, 
        strftime('%Y-%m-%d', timestamp / 1000, 'unixepoch', 'localtime') as date
      FROM batch_scores
      WHERE timestamp >= $startTimeStamp
      GROUP BY date
    ''');
    if (maps.isEmpty) return weeklyEffort;
    for (var map in maps) {
      final date = DateTime.parse(map['date']);
      final count = (map['count'] as int?) ?? 0;
      final index = date.difference(startDate).inDays;
      if (index >= 0 && index < 7) {
        weeklyEffort[index] = count;
      }
    }
    return weeklyEffort;
  }

  Future<int> getNewBatchId() async {
    final db = await database;
    final List<Map> maxIdResult = await db.rawQuery(
      'SELECT MAX(batchId) as maxId FROM words',
    );
    int newBatchId = (maxIdResult.first['maxId'] as int? ?? 0) + 1;
    return newBatchId;
  }

  Future<void> assignBatchIdToNewWords(List<Word> batch, int batchId) async {
    if (batch.isEmpty) return;
    final db = await database;

    List<int> newWordIds = batch
        .where((word) => word.batchId == null)
        .map((word) => word.id)
        .toList();

    if (newWordIds.isEmpty) return;

    await db.update(
      'words',
      {'batchId': batchId},
      where: 'id IN (${newWordIds.map((_) => '?').join(',')})',
      whereArgs: newWordIds,
    );
  }

  Future<int> getUnlearnedWordCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words WHERE mastery_level = ?', [
        0,
      ]),
    );
    return count ?? 0;
  }

  Future<List<Word>> getAllLearnedWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'mastery_level > ?',
      whereArgs: [0],
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getRandomLearnedWords(int count) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'mastery_level > ?',
      whereArgs: [0],
      orderBy: 'RANDOM()',
      limit: count,
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getBatchByBatchId(int batchId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'batchId = ?',
      whereArgs: [batchId],
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<BatchHistory>> getBatchHistory() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        w.batchId, 
        COUNT(w.id) as wordCount,
        
        (SELECT (CAST(s1.correctCount AS REAL) / s1.totalCount) * 100 
         FROM batch_scores s1 
         WHERE s1.batchId = w.batchId 
         ORDER BY s1.timestamp DESC LIMIT 1) as lastScore,
         
        (SELECT MAX((CAST(s2.correctCount AS REAL) / s2.totalCount) * 100) 
         FROM batch_scores s2 
         WHERE s2.batchId = w.batchId) as bestScore
         
      FROM words w
      
      WHERE w.batchId IS NOT NULL 
        AND w.batchId IN (SELECT batchId FROM batch_scores WHERE is_new_session = 1)
        
      GROUP BY w.batchId 
      ORDER BY w.batchId DESC
    ''');

    if (maps.isEmpty) return [];
    return maps
        .map(
          (map) => BatchHistory(
            batchId: map['batchId'],
            wordCount: map['wordCount'],
            lastScore: map['lastScore'],
            bestScore: map['bestScore'],
          ),
        )
        .toList();
  }

  Future<List<String>> getDecoyWords(String correctTr, int count) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      columns: ['tr'],
      where: 'tr != ?',
      whereArgs: [correctTr],
      orderBy: 'RANDOM()',
      limit: count,
    );
    return maps.map((map) => map['tr'] as String).toList();
  }

  Future<List<Word>> getDailySession(int totalBatchSize) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    List<Word> sessionWords = [];

    final List<Map<String, dynamic>> reviewMaps = await db.query(
      'words',
      where:
          'mastery_level > 0 AND mastery_level != ? AND review_due_date <= ?',
      whereArgs: [SpacedRepetition.leechLevel, now],
      orderBy: 'review_due_date ASC',
      limit: totalBatchSize,
    );
    sessionWords.addAll(reviewMaps.map((map) => Word.fromMap(map)));

    int remainingCount = totalBatchSize - sessionWords.length;
    if (remainingCount > 0) {
      final List<Map<String, dynamic>> userNewMaps = await db.query(
        'words',
        where: 'mastery_level = ? AND id > ?',
        whereArgs: [0, _userWordIdThreshold],
        orderBy: 'id ASC',
        limit: remainingCount,
      );
      sessionWords.addAll(userNewMaps.map((map) => Word.fromMap(map)));
    }

    remainingCount = totalBatchSize - sessionWords.length;
    if (remainingCount > 0) {
      final List<Map<String, dynamic>> stockNewMaps = await db.query(
        'words',
        where: 'mastery_level = ? AND id <= ?',
        whereArgs: [0, _userWordIdThreshold],
        orderBy: 'RANDOM()',
        limit: remainingCount,
      );
      sessionWords.addAll(stockNewMaps.map((map) => Word.fromMap(map)));
    }

    sessionWords.shuffle(Random());
    return sessionWords;
  }

  Future<List<Word>> getDifficultWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'mastery_level = ?',
      whereArgs: [SpacedRepetition.leechLevel],
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<int> getDifficultWordCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words WHERE mastery_level = ?', [
        SpacedRepetition.leechLevel,
      ]),
    );
    return count ?? 0;
  }

  Future<void> updateWordMastery(Word word, bool wasCorrect) async {
    final db = await database;
    int currentLevel = word.masteryLevel;
    int currentStreak = word.wrongStreak;
    int newLevel = currentLevel;
    int newStreak = currentStreak;
    int newReviewDate = word.reviewDueDate;

    if (wasCorrect) {
      newStreak = 0;
      if (currentLevel == SpacedRepetition.leechLevel) {
        newLevel = 1;
      } else if (currentLevel < SpacedRepetition.maxLevel) {
        newLevel++;
      }
      newReviewDate = SpacedRepetition.getNextReviewDate(
        newLevel,
      ).millisecondsSinceEpoch;
    } else {
      newStreak++;
      if (newStreak >= SpacedRepetition.leechThreshold) {
        newLevel = SpacedRepetition.leechLevel;
      } else if (currentLevel >= 0) {
        newLevel = (currentLevel ~/ 2);
        if (newLevel == 0 && currentLevel > 0) newLevel = 1;
      }
      newReviewDate = SpacedRepetition.getNextReviewDate(
        1,
      ).millisecondsSinceEpoch;
    }

    await db.update(
      'words',
      {
        'mastery_level': newLevel,
        'wrong_streak': newStreak,
        'review_due_date': newReviewDate,
        'status': (newLevel > 0) ? 'learned' : word.status,
      },
      where: 'id = ?',
      whereArgs: [word.id],
    );
  }

  Future<DetailedStats> getDetailedStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    ).millisecondsSinceEpoch;
    final startOfMonth = DateTime(
      now.year,
      now.month,
      1,
    ).millisecondsSinceEpoch;

    final results = await Future.wait([
      _getStreakCount(db),
      _getStatsForPeriod(db, startOfDay),
      _getStatsForPeriod(db, startOfWeek),
      _getStatsForPeriod(db, startOfMonth),
      _getStatsForPeriod(db, 0),
      getWeeklySuccessChartData(db),
      _getMasteryDistribution(db),
      _getHazineStats(db),
    ]);

    return DetailedStats(
      dailyStreak: results[0] as int,
      todayStats: results[1] as ActivityStats,
      weekStats: results[2] as ActivityStats,
      monthStats: results[3] as ActivityStats,
      allTimeStats: results[4] as ActivityStats,
      weeklySuccessChart: results[5] as List<ChartDataPoint>,
      masteryDistribution: results[6] as Map<String, int>,
      hazineStats: results[7] as Map<String, int>,
    );
  }

  Future<ActivityStats> _getStatsForPeriod(
    Database db,
    int startTimeStamp,
  ) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        COUNT(id) as testCount,
        SUM(totalCount) as totalEfor,
        SUM(correctCount) as correctCount
      FROM batch_scores
      WHERE timestamp >= $startTimeStamp
    ''');
    if (maps.isEmpty) return ActivityStats();
    return ActivityStats.fromMap(maps.first);
  }

  Future<int> _getStreakCount(Database db) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT strftime('%Y-%m-%d', timestamp / 1000, 'unixepoch', 'localtime') as date
      FROM batch_scores
      ORDER BY date DESC
    ''');
    if (maps.isEmpty) return 0;

    int streak = 0;
    DateTime today = DateTime.parse(maps.first['date']);

    if (DateTime.parse(maps.first['date']) !=
        DateTime(today.year, today.month, today.day)) {
      today = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: 1));
    }

    for (var map in maps) {
      final date = DateTime.parse(map['date']);
      if (date ==
          DateTime(
            today.year,
            today.month,
            today.day,
          ).subtract(Duration(days: streak))) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<List<ChartDataPoint>> getWeeklySuccessChartData(Database db) async {
    List<ChartDataPoint> chartData = [];
    final labels = ['Pzt', 'Sal', 'Çrş', 'Per', 'Cum', 'Cmt', 'Paz'];
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      if (day.isAfter(today)) {
        chartData.add(ChartDataPoint(labels[i], 0));
        continue;
      }

      final startOfDay = DateTime(
        day.year,
        day.month,
        day.day,
      ).millisecondsSinceEpoch;
      final endOfDay = DateTime(
        day.year,
        day.month,
        day.day,
        23,
        59,
        59,
      ).millisecondsSinceEpoch;

      final stats = await _getStatsForPeriod(db, startOfDay);
      chartData.add(ChartDataPoint(labels[i], stats.successRate));
    }
    return chartData;
  }

  Future<Map<String, int>> _getMasteryDistribution(Database db) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        CASE
          WHEN mastery_level = 0 THEN 'Yeni'
          WHEN mastery_level = -1 THEN 'Zor'
          WHEN mastery_level BETWEEN 1 AND 3 THEN 'Öğreniliyor'
          WHEN mastery_level BETWEEN 4 AND 7 THEN 'Pekiştirilmiş'
          WHEN mastery_level = 8 THEN 'Usta'
        END as level,
        COUNT(id) as count
      FROM words
      GROUP BY level
    ''');

    Map<String, int> distribution = {
      'Yeni': 0,
      'Öğreniliyor': 0,
      'Pekiştirilmiş': 0,
      'Usta': 0,
      'Zor': 0,
    };
    for (var map in maps) {
      if (map['level'] != null) {
        distribution[map['level']] = map['count'];
      }
    }
    return distribution;
  }

  Future<Map<String, int>> _getHazineStats(Database db) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        (SELECT COUNT(id) FROM words WHERE mastery_level > 0) as ustalikKazanilan,
        (SELECT COUNT(id) FROM words WHERE id > $_userWordIdThreshold) as ekledigimKelimeler,
        (SELECT COUNT(id) FROM words) as toplamHavuz
    ''');
    if (maps.isEmpty) return {};
    return {
      'Ustalık Kazanılan': maps.first['ustalikKazanilan'] ?? 0,
      'Eklediğim Kelimeler': maps.first['ekledigimKelimeler'] ?? 0,
      'Toplam Havuz': maps.first['toplamHavuz'] ?? 0,
    };
  }
}
