import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../../utils/spaced_repetition.dart';
import '../models/word_model.dart';

class WordRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Word>> getDailyReviewWords(
    int batchSize,
    String targetLang,
  ) async {
    final db = await dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> dueWordsData = await db.rawQuery(
      '''
      SELECT w.*, p.mastery_level, p.due_date, p.streak 
      FROM words w
      JOIN progress p ON w.id = p.word_id
      WHERE p.target_lang = ? 
        AND p.mastery_level > 0 
        AND p.mastery_level != ${SpacedRepetition.leechLevel}
        AND p.due_date <= ?
      ORDER BY p.due_date ASC
      LIMIT ?
    ''',
      [targetLang, now, batchSize],
    );

    List<Word> sessionWords = dueWordsData
        .map((map) => Word.fromMap(map))
        .toList();

    int remaining = batchSize - sessionWords.length;
    if (remaining > 0) {
      final List<Map<String, dynamic>> newWordsData = await db.rawQuery(
        '''
        SELECT w.* FROM words w
        LEFT JOIN progress p ON w.id = p.word_id AND p.target_lang = ?
        WHERE (p.word_id IS NULL OR p.mastery_level = 0)
        ORDER BY RANDOM()
        LIMIT ?
      ''',
        [targetLang, remaining],
      );

      sessionWords.addAll(newWordsData.map((map) => Word.fromMap(map)));
    }

    sessionWords.shuffle(Random());
    return sessionWords;
  }

  // ARTIK SADECE HAM VERİ DÖNÜYOR, MANTIK YOK
  Future<List<Map<String, dynamic>>> getRandomCandidates(int limit) async {
    final db = await dbHelper.database;
    return await db.query(
      'words',
      columns: ['content'],
      where: 'id IS NOT NULL',
      orderBy: 'RANDOM()',
      limit: limit,
    );
  }

  Future<void> updateWordProgress(
    int wordId,
    String targetLang,
    bool wasCorrect,
    int currentLevel,
    int currentStreak,
  ) async {
    final db = await dbHelper.database;

    int newLevel = currentLevel;
    int newStreak = currentStreak;
    int newReviewDate = 0;

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
        newLevel = max(1, currentLevel ~/ 2);
      }
      newReviewDate = SpacedRepetition.getNextReviewDate(
        1,
      ).millisecondsSinceEpoch;
    }

    await db.rawInsert(
      '''
      INSERT OR REPLACE INTO progress (word_id, target_lang, mastery_level, due_date, streak)
      VALUES (?, ?, ?, ?, ?)
    ''',
      [wordId, targetLang, newLevel, newReviewDate, newStreak],
    );
  }

  Future<List<Word>> getDifficultWords(String targetLang) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT w.*, p.mastery_level, p.due_date, p.streak
      FROM words w
      JOIN progress p ON w.id = p.word_id
      WHERE p.target_lang = ? AND p.mastery_level = ${SpacedRepetition.leechLevel}
    ''',
      [targetLang],
    );

    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<int> getDailyReviewCount(int batchSize, String targetLang) async {
    final db = await dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final dueCount =
        Sqflite.firstIntValue(
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

    final newCount =
        Sqflite.firstIntValue(
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
}
