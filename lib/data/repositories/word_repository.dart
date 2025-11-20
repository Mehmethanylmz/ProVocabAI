import 'dart:math';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../../utils/spaced_repetition.dart';
import '../models/word_model.dart';

class WordRepository {
  final dbHelper = DatabaseHelper.instance;

  // FİLTRELİ KELİME ÇEKME (TEST İÇİN)
  Future<List<Word>> getFilteredWords({
    required String targetLang,
    required List<String> categories,
    required List<String> grammar,
    required String mode,
    required int batchSize,
  }) async {
    final db = await dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = "1=1";
    List<dynamic> args = [];

    // Kategori Filtresi
    if (categories.isNotEmpty && !categories.contains('all')) {
      String catQuery = "(";
      for (int i = 0; i < categories.length; i++) {
        catQuery += "categories LIKE ?";
        args.add('%"${categories[i]}"%');
        if (i < categories.length - 1) catQuery += " OR ";
      }
      catQuery += ")";
      whereClause += " AND $catQuery";
    }

    // Gramer Filtresi
    if (grammar.isNotEmpty && !grammar.contains('all')) {
      String grammarQuery = "(";
      for (int i = 0; i < grammar.length; i++) {
        grammarQuery += "part_of_speech = ?";
        args.add(grammar[i]);
        if (i < grammar.length - 1) grammarQuery += " OR ";
      }
      grammarQuery += ")";
      whereClause += " AND $grammarQuery";
    }

    // Mod Filtresi
    if (mode == 'daily') {
      // Günlük tekrarlar (Progress tablosunda zamanı gelenler)
      String dailyWhere =
          "EXISTS (SELECT 1 FROM progress p WHERE p.word_id = words.id AND p.target_lang = ? AND p.mastery_level > 0 AND p.mastery_level != ${SpacedRepetition.leechLevel} AND p.due_date <= ?)";
      whereClause += " AND $dailyWhere";
      args.add(targetLang);
      args.add(now);
    } else if (mode == 'difficult') {
      // Zor kelimeler
      String diffWhere =
          "EXISTS (SELECT 1 FROM progress p WHERE p.word_id = words.id AND p.target_lang = ? AND p.mastery_level = ${SpacedRepetition.leechLevel})";
      whereClause += " AND $diffWhere";
      args.add(targetLang);
    }
    // 'custom' modunda ekstra filtre yok, yukarıdaki kategori/gramer yeterli.

    String sql =
        'SELECT * FROM words WHERE $whereClause ORDER BY RANDOM() LIMIT ?';
    args.add(batchSize);

    final List<Map<String, dynamic>> rawData = await db.rawQuery(sql, args);
    return rawData.map((map) => Word.fromMap(map)).toList();
  }

  // CANLI SAYAÇ SORGUSU
  Future<int> getFilteredReviewCount({
    required String targetLang,
    required List<String> categories,
    required List<String> grammar,
  }) async {
    final db = await dbHelper.database;
    String whereClause = "1=1";
    List<dynamic> args = [];

    if (categories.isNotEmpty && !categories.contains('all')) {
      String catQuery = "(";
      for (int i = 0; i < categories.length; i++) {
        catQuery += "categories LIKE ?";
        args.add('%"${categories[i]}"%');
        if (i < categories.length - 1) catQuery += " OR ";
      }
      catQuery += ")";
      whereClause += " AND $catQuery";
    }

    if (grammar.isNotEmpty && !grammar.contains('all')) {
      String grammarQuery = "(";
      for (int i = 0; i < grammar.length; i++) {
        grammarQuery += "part_of_speech = ?";
        args.add(grammar[i]);
        if (i < grammar.length - 1) grammarQuery += " OR ";
      }
      grammarQuery += ")";
      whereClause += " AND $grammarQuery";
    }

    final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM words WHERE $whereClause', args));
    return count ?? 0;
  }

  // LİSTELERİ DOLDURMA
  Future<List<String>> getUniquePartsOfSpeech() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
        'SELECT DISTINCT part_of_speech FROM words WHERE part_of_speech IS NOT NULL AND part_of_speech != ""');
    return result.map((e) => e['part_of_speech'] as String).toList();
  }

  Future<List<String>> getAllUniqueCategories() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
        'SELECT categories FROM words WHERE categories IS NOT NULL AND categories != "[]"');

    final Set<String> uniqueCategories = {};
    for (var row in result) {
      try {
        final catString = row['categories'] as String;
        final List<dynamic> cats = jsonDecode(catString);
        for (var c in cats) {
          uniqueCategories.add(c.toString().trim());
        }
      } catch (e) {}
    }
    final sortedList = uniqueCategories.toList()..sort();
    return sortedList;
  }

  // --- DİĞER YARDIMCI METODLAR (ESKİ SİSTEM DESTEĞİ İÇİN) ---

  Future<int> getDailyReviewCount(int batchSize, String targetLang) async {
    final db = await dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final dueCount = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
      SELECT COUNT(*) FROM progress 
      WHERE target_lang = ? 
      AND mastery_level > 0 
      AND mastery_level != ${SpacedRepetition.leechLevel}
      AND due_date <= ?
    ''',
            [targetLang, now],
          ),
        ) ??
        0;

    final newCount = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
      SELECT COUNT(*) FROM words w
      LEFT JOIN progress p ON w.id = p.word_id AND p.target_lang = ?
      WHERE p.word_id IS NULL OR p.mastery_level = 0
    ''',
            [targetLang],
          ),
        ) ??
        0;

    if (dueCount >= batchSize) return batchSize;
    return dueCount + min(newCount, batchSize - dueCount);
  }

  Future<List<Word>> getDailyReviewWords(
      int batchSize, String targetLang) async {
    // Bu metod artık getFilteredWords ile kapsanıyor ama eski çağrılar için tutuyoruz
    return getFilteredWords(
        targetLang: targetLang,
        categories: ['all'],
        grammar: ['all'],
        mode: 'daily',
        batchSize: batchSize);
  }

  Future<List<Word>> getDifficultWords(String targetLang) async {
    // Bu da aynı şekilde
    return getFilteredWords(
        targetLang: targetLang,
        categories: ['all'],
        grammar: ['all'],
        mode: 'difficult',
        batchSize: 50);
  }

  Future<void> updateWordProgress(int wordId, String targetLang,
      bool wasCorrect, int currentLevel, int currentStreak) async {
    final db = await dbHelper.database;
    int newLevel = currentLevel;
    int newStreak = currentStreak;
    int newReviewDate = 0;

    if (wasCorrect) {
      newStreak = 0;
      newLevel = (currentLevel == SpacedRepetition.leechLevel)
          ? 1
          : (currentLevel < SpacedRepetition.maxLevel
              ? currentLevel + 1
              : currentLevel);
      newReviewDate =
          SpacedRepetition.getNextReviewDate(newLevel).millisecondsSinceEpoch;
    } else {
      newStreak++;
      newLevel = (newStreak >= SpacedRepetition.leechThreshold)
          ? SpacedRepetition.leechLevel
          : max(1, currentLevel ~/ 2);
      newReviewDate =
          SpacedRepetition.getNextReviewDate(1).millisecondsSinceEpoch;
    }

    await db.rawInsert('''
      INSERT OR REPLACE INTO progress (word_id, target_lang, mastery_level, due_date, streak)
      VALUES (?, ?, ?, ?, ?)
    ''', [wordId, targetLang, newLevel, newReviewDate, newStreak]);
  }

  Future<List<Map<String, dynamic>>> getRandomCandidates(int limit) async {
    final db = await dbHelper.database;
    return await db.query('words',
        columns: ['content'],
        where: 'id IS NOT NULL',
        orderBy: 'RANDOM()',
        limit: limit);
  }
}
