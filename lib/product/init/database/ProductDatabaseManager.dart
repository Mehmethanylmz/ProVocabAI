import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';

class ProductDatabaseManager {
  static final ProductDatabaseManager _instance =
      ProductDatabaseManager._init();
  static ProductDatabaseManager get instance => _instance;

  static Database? _database;

  ProductDatabaseManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
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
        last_seen INTEGER DEFAULT 0,
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
    if (oldVersion < 2) {
      // v1 → v2: progress tablosuna last_seen kolonu ekle
      await db.execute(
        'ALTER TABLE progress ADD COLUMN last_seen INTEGER DEFAULT 0',
      );
    }
  }
}
