import 'package:dartz/dartz.dart';
import '../../../../core/base/base_usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_stats_entity.dart';
import '../repositories/i_dashboard_repository.dart';

class GetDashboardStats implements BaseUseCase<DashboardStatsEntity, String> {
  final IDashboardRepository _repository;

  GetDashboardStats(this._repository);

  @override
  Future<Either<Failure, DashboardStatsEntity>> call(String targetLang) {
    return _repository.getDashboardStats(targetLang);
  }
}
