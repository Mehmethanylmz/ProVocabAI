import 'dart:convert';
import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/spaced_repetition.dart';
import '../../../../product/init/database/ProductDatabaseManager.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/i_word_repository.dart';
import '../models/word_model.dart';

class WordRepositoryImpl implements IWordRepository {
  final ProductDatabaseManager _dbManager;

  WordRepositoryImpl(this._dbManager);

  // ────────────────────────────────────────────────────────────────────────
  // ASSET VERI DOLUMU
  // Uygulama ilk açılışta assets/dataset/words.json dosyasından verileri
  // SQLite'a aktarır. Bu yöntem onboarding tamamlandığında çağrılır.
  // ────────────────────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> downloadInitialContent(
      String nativeLang, String targetLang) async {
    try {
      // 1. Asset'ten JSON'u oku (async — UI bloke etmez)
      final jsonString =
          await rootBundle.loadString(AppConstants.wordsDatasetPath);

      // 2. JSON parse + model dönüşümü isolate'de yap (UI bloke etmez)
      final List<Map<String, dynamic>> parsedMaps =
          await compute(_parseWordJson, jsonString);

      // 3. SQLite'a batch insert (chunked)
      final db = await _dbManager.database;
      const chunkSize = 500;
      final totalChunks = (parsedMaps.length / chunkSize).ceil();

      for (int chunk = 0; chunk < totalChunks; chunk++) {
        final start = chunk * chunkSize;
        final end = (start + chunkSize).clamp(0, parsedMaps.length);
        final chunkList = parsedMaps.sublist(start, end);

        final batch = db.batch();
        for (final map in chunkList) {
          batch.insert(
            'words',
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Kelime veritabanı yüklenemedi: $e'));
    }
  }

  /// Top-level fonksiyon: isolate'de JSON parse + model map dönüşümü
  List<Map<String, dynamic>> _parseWordJson(String jsonString) {
    final List<dynamic> rawList = jsonDecode(jsonString) as List<dynamic>;
    final result = <Map<String, dynamic>>[];
    for (final item in rawList) {
      try {
        final word = WordModel.fromJson(item as Map<String, dynamic>);
        result.add(word.toSqlMap());
      } catch (_) {
        // Bozuk kaydı atla
      }
    }
    return result;
  }

  @override
  Future<Either<Failure, List<WordEntity>>> getFilteredWords({
    required String targetLang,
    required List<String> categories,
    required String mode,
    required int batchSize,
  }) async {
    try {
      final db = await _dbManager.database;
      final now = DateTime.now().millisecondsSinceEpoch;
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

      if (mode == 'daily') {
        String dailyWhere =
            "EXISTS (SELECT 1 FROM progress p WHERE p.word_id = words.id AND p.target_lang = ? AND p.mastery_level > 0 AND p.mastery_level != ${SpacedRepetition.leechLevel} AND p.due_date <= ?)";
        whereClause += " AND $dailyWhere";
        args.add(targetLang);
        args.add(now);
      } else if (mode == 'difficult') {
        String diffWhere =
            "EXISTS (SELECT 1 FROM progress p WHERE p.word_id = words.id AND p.target_lang = ? AND p.mastery_level = ${SpacedRepetition.leechLevel})";
        whereClause += " AND $diffWhere";
        args.add(targetLang);
      }

      String sql =
          'SELECT * FROM words WHERE $whereClause ORDER BY RANDOM() LIMIT ?';
      args.add(batchSize);

      final List<Map<String, dynamic>> rawData = await db.rawQuery(sql, args);
      final List<WordEntity> entities =
          rawData.map((map) => WordModel.fromMap(map)).toList();

      return Right(entities);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getFilteredReviewCount({
    required String targetLang,
    required List<String> categories,
  }) async {
    try {
      final db = await _dbManager.database;
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

      final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM words WHERE $whereClause', args));
      return Right(count ?? 0);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAllUniqueCategories() async {
    try {
      final db = await _dbManager.database;
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
      return Right(uniqueCategories.toList()..sort());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getDailyReviewCount(
      int dailyGoal, String targetLang) async {
    try {
      final db = await _dbManager.database;

      // Bugünün gün başı ve sonu (milliseconds)
      final now = DateTime.now();
      final startOfDay =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
          .millisecondsSinceEpoch;

      // Bugün gerçekten incelenen (last_seen bugün olan) kelimeler
      final count = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM progress
        WHERE target_lang = ?
        AND last_seen >= ?
        AND last_seen <= ?
      ''', [targetLang, startOfDay, endOfDay])) ?? 0;

      return Right(count);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WordEntity>>> getDifficultWords(
      String targetLang) async {
    try {
      final result = await getFilteredWords(
          targetLang: targetLang,
          categories: ['all'],
          mode: 'difficult',
          batchSize: 50);
      return result;
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateWordProgress(
      int wordId,
      String targetLang,
      bool wasCorrect,
      int currentLevel,
      int currentStreak) async {
    try {
      final db = await _dbManager.database;
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
        INSERT OR REPLACE INTO progress (word_id, target_lang, mastery_level, due_date, streak, last_seen)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        wordId,
        targetLang,
        newLevel,
        newReviewDate,
        newStreak,
        DateTime.now().millisecondsSinceEpoch
      ]);

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRandomCandidates(
      int limit) async {
    try {
      final db = await _dbManager.database;
      final result = await db.query('words',
          columns: ['content'],
          where: 'id IS NOT NULL',
          orderBy: 'RANDOM()',
          limit: limit);
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getWordCount() async {
    try {
      final db = await _dbManager.database;
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM words'));
      return Right(count ?? 0);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
