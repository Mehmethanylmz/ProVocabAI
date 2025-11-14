import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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
      version: 8,
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
  mastery_level INTEGER DEFAULT 0 NOT NULL,
  review_due_date INTEGER DEFAULT 0 NOT NULL,
  wrong_streak INTEGER DEFAULT 0 NOT NULL
)
''');
    await db.execute('''
CREATE TABLE test_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  totalCount INTEGER NOT NULL,
  correctCount INTEGER NOT NULL,
  durationSeconds INTEGER NOT NULL,
  successRate REAL NOT NULL
)
''');
    await db.execute('''
CREATE TABLE progress_snapshots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  unlearned INTEGER DEFAULT 0,
  struggling INTEGER DEFAULT 0,
  novice INTEGER DEFAULT 0,
  apprentice INTEGER DEFAULT 0,
  expert INTEGER DEFAULT 0
)
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 7) {
      await db.execute('''
CREATE TABLE test_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  totalCount INTEGER NOT NULL,
  correctCount INTEGER NOT NULL,
  durationSeconds INTEGER NOT NULL,
  successRate REAL NOT NULL
)
''');
      await db.execute('DROP TABLE IF EXISTS batch_scores');
    }
    if (oldVersion < 8) {
      await db.execute('''
CREATE TABLE progress_snapshots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date INTEGER NOT NULL,
  unlearned INTEGER DEFAULT 0,
  struggling INTEGER DEFAULT 0,
  novice INTEGER DEFAULT 0,
  apprentice INTEGER DEFAULT 0,
  expert INTEGER DEFAULT 0
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
        'example_sentence': item['example_sentence'] ?? '',
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
    await batch.commit();
  }
}
