import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../product/init/database/ProductDatabaseManager.dart';
import '../../domain/entities/test_result_entity.dart';
import '../../domain/repositories/i_test_repository.dart';
import '../models/test_result_model.dart';

class TestRepositoryImpl implements ITestRepository {
  final ProductDatabaseManager _dbManager;

  TestRepositoryImpl(this._dbManager);

  @override
  Future<Either<Failure, void>> saveTestResult(TestResultEntity result) async {
    try {
      final db = await _dbManager.database;
      final model = TestResultModel(
        date: result.date,
        questions: result.questions,
        correct: result.correct,
        wrong: result.wrong,
        duration: result.duration,
        successRate: result.successRate,
      );

      await db.insert('test_results', model.toMap());
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TestResultEntity>>> getTestHistory() async {
    try {
      final db = await _dbManager.database;
      final now = DateTime.now();
      final threeDaysAgo =
          now.subtract(const Duration(days: 3)).millisecondsSinceEpoch;

      final maps = await db.query(
        'test_results',
        where: 'timestamp >= ?',
        whereArgs: [threeDaysAgo],
        orderBy: 'timestamp DESC',
      );

      final List<TestResultEntity> results =
          maps.map((e) => TestResultModel.fromMap(e)).toList();
      return Right(results);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOldTestHistory() async {
    try {
      final db = await _dbManager.database;
      final now = DateTime.now();
      final threeDaysAgo =
          now.subtract(const Duration(days: 3)).millisecondsSinceEpoch;

      await db.delete(
        'test_results',
        where: 'timestamp < ?',
        whereArgs: [threeDaysAgo],
      );
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
