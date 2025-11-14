import 'dart:math';

import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../../models/word_model.dart';
import '../../utils/spaced_repetition.dart';

class WordRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<List<Word>> getDailyReviewWords(int totalBatchSize) async {
    final db = await dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> reviewMaps = await db.query(
      'words',
      where:
          'mastery_level > 0 AND mastery_level != ? AND review_due_date <= ?',
      whereArgs: [SpacedRepetition.leechLevel, now],
      orderBy: 'review_due_date ASC',
      limit: totalBatchSize,
    );

    List<Word> sessionWords = reviewMaps
        .map((map) => Word.fromMap(map))
        .toList();

    int remainingCount = totalBatchSize - sessionWords.length;

    if (remainingCount > 0) {
      final List<Map<String, dynamic>> newMaps = await db.query(
        'words',
        where: 'mastery_level = ?',
        whereArgs: [0],
        orderBy: 'RANDOM()',
        limit: remainingCount,
      );
      sessionWords.addAll(newMaps.map((map) => Word.fromMap(map)));
    }

    sessionWords.shuffle(Random());
    return sessionWords;
  }

  Future<int> getDailyReviewCount(int totalBatchSize) async {
    final db = await dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final reviewCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(id) FROM words WHERE mastery_level > 0 AND mastery_level != ? AND review_due_date <= ?',
        [SpacedRepetition.leechLevel, now],
      ),
    );

    final newCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(id) FROM words WHERE mastery_level = ?', [
        0,
      ]),
    );

    final totalDue = (reviewCount ?? 0);
    final totalNew = (newCount ?? 0);

    if (totalDue >= totalBatchSize) {
      return totalBatchSize;
    }

    return totalDue + min(totalNew, totalBatchSize - totalDue);
  }

  Future<List<Word>> getDifficultWords() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: 'mastery_level = ?',
      whereArgs: [SpacedRepetition.leechLevel],
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<int> getDifficultWordCount() async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words WHERE mastery_level = ?', [
        SpacedRepetition.leechLevel,
      ]),
    );
    return count ?? 0;
  }

  Future<void> updateWordMastery(Word word, bool wasCorrect) async {
    final db = await dbHelper.database;
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
      },
      where: 'id = ?',
      whereArgs: [word.id],
    );
  }

  Future<List<String>> getDecoyWords(String correctTr, int count) async {
    final db = await dbHelper.database;
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

  Future<int> getUnlearnedWordCount() async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM words WHERE mastery_level = ?', [
        0,
      ]),
    );
    return count ?? 0;
  }
}
