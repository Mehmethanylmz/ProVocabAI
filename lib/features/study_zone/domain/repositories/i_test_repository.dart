import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/test_result_entity.dart';

abstract class ITestRepository {
  Future<Either<Failure, void>> saveTestResult(TestResultEntity result);
  Future<Either<Failure, List<TestResultEntity>>> getTestHistory();
  Future<Either<Failure, void>> deleteOldTestHistory();
}
