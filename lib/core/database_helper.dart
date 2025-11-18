import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../data/models/word_model.dart';

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
      version: 1,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words ( 
        id INTEGER PRIMARY KEY, 
        part_of_speech TEXT,
        transcription TEXT,
        categories TEXT,
        content TEXT,
        sentences TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE progress (
        word_id INTEGER NOT NULL,
        target_lang TEXT NOT NULL,
        mastery_level INTEGER DEFAULT 0,
        due_date INTEGER DEFAULT 0,
        streak INTEGER DEFAULT 0,
        PRIMARY KEY (word_id, target_lang),
        FOREIGN KEY (word_id) REFERENCES words (id)
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
    if (oldVersion < 9) {
      await db.execute('DROP TABLE IF EXISTS words');
      await db.execute('DROP TABLE IF EXISTS progress');
      await _createDB(db, newVersion);
    }
  }

  Future<void> populateDatabase() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words'),
    );

    if (count != null && count > 0) return;

    try {
      final String response =
          await rootBundle.loadString('assets/dataset/words.json');
      final List<dynamic> data = json.decode(response);
      Batch batch = db.batch();

      for (var item in data) {
        Word word = Word.fromJson(item);
        batch.insert(
          'words',
          word.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      if (kDebugMode) {
        print("DB Populate Error: $e");
      }
    }
  }
}
