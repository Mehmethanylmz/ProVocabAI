import 'package:dartz/dartz.dart';
import '../../../../core/base/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/word_entity.dart';
import '../repositories/i_study_repository.dart';

// Params sınıfı: UseCase'e parametre geçmek için
class GetDailyWordsParams {
  final String targetLang;
  final int limit;
  GetDailyWordsParams({required this.targetLang, this.limit = 10});
}

class GetDailyWords
    implements BaseUseCase<List<WordEntity>, GetDailyWordsParams> {
  final IStudyRepository _repository;

  GetDailyWords(this._repository);

  @override
  Future<Either<Failure, List<WordEntity>>> call(
      GetDailyWordsParams params) async {
    return await _repository.getWordsForStudy(
      mode: 'daily',
      targetLang: params.targetLang,
      limit: params.limit,
    );
  }
}
