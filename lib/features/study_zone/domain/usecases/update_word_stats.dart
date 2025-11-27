import 'package:dartz/dartz.dart';
import '../../../../core/base/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/i_study_repository.dart';

class UpdateWordStatsParams {
  final int wordId;
  final bool isCorrect;
  final int currentLevel;
  final int currentStreak;
  final String targetLang;

  UpdateWordStatsParams({
    required this.wordId,
    required this.isCorrect,
    required this.currentLevel,
    required this.currentStreak,
    required this.targetLang,
  });
}

class UpdateWordStats implements BaseUseCase<void, UpdateWordStatsParams> {
  final IStudyRepository _repository;

  UpdateWordStats(this._repository);

  @override
  Future<Either<Failure, void>> call(UpdateWordStatsParams params) async {
    return await _repository.updateWordStats(
      wordId: params.wordId,
      isCorrect: params.isCorrect,
      currentLevel: params.currentLevel,
      currentStreak: params.currentStreak,
      targetLang: params.targetLang,
    );
  }
}
