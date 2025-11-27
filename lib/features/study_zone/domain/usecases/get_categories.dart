import 'package:dartz/dartz.dart';
import '../../../../core/base/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../repositories/i_study_repository.dart';

class GetCategories implements BaseUseCase<List<String>, NoParams> {
  final IStudyRepository _repository;

  GetCategories(this._repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await _repository.getCategories();
  }
}
