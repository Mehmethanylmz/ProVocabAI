import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/word_model.dart';
import '../models/dashboard_stats.dart';
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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE words ( 
  id INTEGER PRIMARY KEY, en TEXT NOT NULL, tr TEXT NOT NULL, meaning TEXT,
  example_sentence TEXT, status TEXT NOT NULL, batchId INTEGER DEFAULT NULL 
)
''');
    await db.execute('''
CREATE TABLE batch_scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT, batchId INTEGER NOT NULL, 
  correctCount INTEGER NOT NULL, totalCount INTEGER NOT NULL, timestamp INTEGER NOT NULL
)
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE batch_scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT, batchId INTEGER NOT NULL, 
  correctCount INTEGER NOT NULL, totalCount INTEGER NOT NULL, timestamp INTEGER NOT NULL
)
''');
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
      Map<String, dynamic> wordMap = {
        'id': item['id'],
        'en': item['en'],
        'tr': item['tr'],
        'meaning': item['meaning'],
        'example_sentence': item['example_sentence'],
        'status': 'unseen',
      };
      batch.insert(
        'words',
        wordMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.apply();
  }

  Future<void> insertBatchScore(int batchId, int correct, int total) async {
    final db = await database;
    await db.insert('batch_scores', {
      'batchId': batchId,
      'correctCount': correct,
      'totalCount': total,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
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
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - 6,
    ).millisecondsSinceEpoch;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(id) FROM words WHERE status = 'learned') as totalLearnedWords,
        (SELECT SUM(totalCount) FROM batch_scores 
         WHERE timestamp >= $startOfDay) as wordsLearnedToday,
        (SELECT SUM(totalCount) FROM batch_scores 
         WHERE timestamp >= $startOfWeek) as wordsLearnedThisWeek,
        (SELECT AVG((CAST(correctCount AS REAL) / totalCount) * 100) 
         FROM batch_scores) as overallSuccessRate
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
        strftime('%Y-%m-%d', timestamp / 1000, 'unixepoch') as date
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

  Future<List<Word>> getNewWordBatch(int batchSize) async {
    final db = await database;
    final List<Map<String, dynamic>> idMaps = await db.query(
      'words',
      columns: ['id'],
      where: 'status = ?',
      whereArgs: ['unseen'],
    );
    if (idMaps.isEmpty) return [];
    List<int> ids = idMaps.map((map) => map['id'] as int).toList();
    ids.shuffle(Random());
    List<int> selectedIds = ids.take(batchSize).toList();
    if (selectedIds.isEmpty) return [];
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'id IN (${selectedIds.map((_) => '?').join(',')})',
      whereArgs: selectedIds,
    );
    final wordsList = maps.map((map) => Word.fromMap(map)).toList();
    wordsList.sort(
      (a, b) => selectedIds.indexOf(a.id).compareTo(selectedIds.indexOf(b.id)),
    );
    return wordsList;
  }

  Future<int> markBatchAsLearned(List<Word> batch) async {
    if (batch.isEmpty) return 0;
    final db = await database;
    final List<Map> maxIdResult = await db.rawQuery(
      'SELECT MAX(batchId) as maxId FROM words',
    );
    int newBatchId = (maxIdResult.first['maxId'] as int? ?? 0) + 1;
    List<int> wordIds = batch.map((word) => word.id).toList();
    await db.update(
      'words',
      {'status': 'learned', 'batchId': newBatchId},
      where: 'id IN (${wordIds.map((_) => '?').join(',')})',
      whereArgs: wordIds,
    );
    return newBatchId;
  }

  Future<int> getUnlearnedWordCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words WHERE status = ?', [
        'unseen',
      ]),
    );
    return count ?? 0;
  }

  Future<List<Word>> getAllLearnedWords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'status = ?',
      whereArgs: ['learned'],
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getRandomLearnedWords(int count) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'status = ?',
      whereArgs: ['learned'],
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
        w.batchId, COUNT(w.id) as wordCount,
        (SELECT (CAST(s1.correctCount AS REAL) / s1.totalCount) * 100 
         FROM batch_scores s1 WHERE s1.batchId = w.batchId 
         ORDER BY s1.timestamp DESC LIMIT 1) as lastScore,
        (SELECT MAX((CAST(s2.correctCount AS REAL) / s2.totalCount) * 100) 
         FROM batch_scores s2 WHERE s2.batchId = w.batchId) as bestScore
      FROM words w
      WHERE w.status = "learned" AND w.batchId IS NOT NULL 
      GROUP BY w.batchId ORDER BY w.batchId DESC
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
}
