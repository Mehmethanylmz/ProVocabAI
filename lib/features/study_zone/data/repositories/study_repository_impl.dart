import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/spaced_repetition.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/i_study_repository.dart';
import '../datasources/word_local_source.dart';

class StudyRepositoryImpl implements IStudyRepository {
  final WordLocalDataSource _localDataSource;

  StudyRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, List<WordEntity>>> getWordsForStudy({
    required String mode,
    required String targetLang,
    List<String>? categories,
    int limit = 10,
  }) async {
    try {
      final models =
          await _localDataSource.getDailyReviewWords(targetLang, limit);

      // toEntity() metodunu WordModel içine eklediğimiz için artık çalışacak
      final entities = models.map((e) => e.toEntity()).toList();

      return Right(entities);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateWordStats({
    required int wordId,
    required bool isCorrect,
    required int currentLevel,
    required int currentStreak,
    required String targetLang,
  }) async {
    try {
      int newLevel = currentLevel;
      int newStreak = currentStreak;
      int newReviewDate = 0;

      if (isCorrect) {
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
            : (currentLevel > 1 ? currentLevel ~/ 2 : 1);
        newReviewDate =
            SpacedRepetition.getNextReviewDate(1).millisecondsSinceEpoch;
      }

      await _localDataSource.updateWordProgress(
          wordId, targetLang, newLevel, newReviewDate, newStreak);

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    // Burası da normalde dataSource'dan gelmeli ama şimdilik sabit kalsın
    return const Right(['General', 'Business', 'Travel']);
  }
}
