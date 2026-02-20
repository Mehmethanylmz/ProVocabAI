import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/word_entity.dart';

abstract class IWordRepository {
  Future<Either<Failure, List<WordEntity>>> getFilteredWords({
    required String targetLang,
    required List<String> categories,
    required String mode,
    required int batchSize,
  });

  Future<Either<Failure, void>> downloadInitialContent(
      String nativeLang, String targetLang);

  Future<Either<Failure, int>> getFilteredReviewCount({
    required String targetLang,
    required List<String> categories,
  });

  Future<Either<Failure, List<String>>> getAllUniqueCategories();
  Future<Either<Failure, int>> getDailyReviewCount(
      int batchSize, String targetLang);
  Future<Either<Failure, List<WordEntity>>> getDifficultWords(
      String targetLang);

  Future<Either<Failure, void>> updateWordProgress(int wordId,
      String targetLang, bool wasCorrect, int currentLevel, int currentStreak);

  Future<Either<Failure, List<Map<String, dynamic>>>> getRandomCandidates(
      int limit);

  /// Kelime tablosundaki toplam kayıt sayısı.
  /// Sıfır ise veri hiç yüklenmemiş demektir.
  Future<Either<Failure, int>> getWordCount();
}
