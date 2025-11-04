// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../models/word_model.dart';

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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE words ( 
  id INTEGER PRIMARY KEY, 
  en TEXT NOT NULL,
  tr TEXT NOT NULL,
  meaning TEXT,
  example_sentence TEXT,
  status TEXT NOT NULL
  )
''');
  }

  // UYGULAMANIN İLK AÇILIŞINDA SADECE BİR KEZ ÇALIŞACAK
  Future<void> populateDatabase() async {
    final db = await instance.database;

    // Veritabanı dolu mu diye kontrol et
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words'),
    );
    if (count != null && count > 0) {
      print("Veritabanı zaten dolu. Yükleme atlanıyor.");
      return;
    }

    print("Veritabanı ilk kez dolduruluyor... Bu işlem biraz sürebilir.");
    // JSON dosyasını yükle
    final String response = await rootBundle.loadString('assets/words.json');
    final List<dynamic> data = json.decode(response);

    // Verileri toplu halde ekle (Çok daha hızlı)
    Batch batch = db.batch();
    for (var item in data) {
      final word = Word.fromMap(item);
      batch.insert(
        'words',
        word.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.apply();
    print("Veritabanı başarıyla dolduruldu!");
  }

  // --- İSTEDİĞİN ANA FONKSİYONLAR ---

  // 1. GÖRÜLMEMİŞ KELİMELERDEN YENİ BİR GRUP AL
  Future<List<Word>> getNewWordBatch(int batchSize) async {
    final db = await instance.database;

    // 1. 'unseen' (görülmemiş) durumdaki kelimelerden 'batchSize' kadarını al
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'status = ?',
      whereArgs: ['unseen'],
      limit: batchSize,
    );

    if (maps.isEmpty) {
      return []; // Görülecek kelime kalmamış
    }

    List<int> wordIds = maps.map((map) => map['id'] as int).toList();

    // 2. Bu kelimelerin durumunu 'learning' (öğreniliyor) olarak güncelle
    await db.update(
      'words',
      {'status': 'learning'},
      where: 'id IN (${wordIds.map((_) => '?').join(',')})',
      whereArgs: wordIds,
    );

    // 3. 'learning' olarak işaretlenen kelime listesini uygulamaya gönder
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  // 2. MEVCUT GRUBU "ÖĞRENİLDİ" OLARAK İŞARETLE
  Future<void> markCurrentBatchAsLearned() async {
    final db = await instance.database;
    int count = await db.update(
      'words',
      {'status': 'learned'},
      where: 'status = ?',
      whereArgs: ['learning'],
    );
    print("$count adet kelime 'learned' olarak işaretlendi.");
  }

  // 3. ÖĞRENİLMEMİŞ KELİME SAYISINI AL (İlerleme için)
  Future<int> getUnlearnedWordCount() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words WHERE status = ?', [
        'unseen',
      ]),
    );
    return count ?? 0;
  }
}
