import 'dart:convert';
import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/base/service_helper.dart';
import '../../../../core/constants/enum/app_enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/init/network/network_manager.dart';
import '../../../../core/utils/spaced_repetition.dart';
import '../../../../product/init/database/ProductDatabaseManager.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/i_word_repository.dart';
import '../models/word_model.dart';

class WordRepositoryImpl with ServiceHelper implements IWordRepository {
  final ProductDatabaseManager _dbManager;
  final NetworkManager _networkManager = NetworkManager.instance;

  WordRepositoryImpl(this._dbManager);

  @override
  Future<Either<Failure, void>> downloadInitialContent(
      String nativeLang, String targetLang) async {
    return await serve<void>(() async {
      final remoteWords = await _networkManager.send<List<WordModel>>(
        '/words/sync',
        type: HttpTypes.GET,
        queryParameters: {
          'native_lang': nativeLang,
          'target_lang': targetLang,
        },
        parseModel: (json) {
          if (json is List) {
            return json.map((e) => WordModel.fromJson(e)).toList();
          }
          return [];
        },
      );

      if (remoteWords != null) {
        final db = await _dbManager.database;
        final batch = db.batch();

        for (var word in remoteWords) {
          batch.insert(
            'words',
            word.toSqlMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  @override
  Future<Either<Failure, List<WordEntity>>> getFilteredWords({
    required String targetLang,
    required List<String> categories,
    required List<String> grammar,
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
    required List<String> grammar,
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
  Future<Either<Failure, List<String>>> getUniquePartsOfSpeech() async {
    try {
      final db = await _dbManager.database;
      final result = await db.rawQuery(
          'SELECT DISTINCT part_of_speech FROM words WHERE part_of_speech IS NOT NULL AND part_of_speech != ""');
      return Right(result.map((e) => e['part_of_speech'] as String).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getDailyReviewCount(
      int batchSize, String targetLang) async {
    try {
      final db = await _dbManager.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final dueCount = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM progress 
        WHERE target_lang = ? 
        AND mastery_level > 0 
        AND mastery_level != ${SpacedRepetition.leechLevel}
        AND due_date <= ?
      ''', [targetLang, now])) ?? 0;

      final newCount = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM words w
        LEFT JOIN progress p ON w.id = p.word_id AND p.target_lang = ?
        WHERE p.word_id IS NULL OR p.mastery_level = 0
      ''', [targetLang])) ?? 0;

      if (dueCount >= batchSize) return Right(batchSize);
      return Right(dueCount + min(newCount, batchSize - dueCount));
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
          grammar: ['all'],
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
        INSERT OR REPLACE INTO progress (word_id, target_lang, mastery_level, due_date, streak)
        VALUES (?, ?, ?, ?, ?)
      ''', [wordId, targetLang, newLevel, newReviewDate, newStreak]);

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
}
