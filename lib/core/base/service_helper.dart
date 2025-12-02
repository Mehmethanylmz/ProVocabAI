import 'package:dartz/dartz.dart';
import '../error/failures.dart';
import '../error/exceptions.dart';

// Bu Mixin'i Repository'lere ekleyeceğiz ("with" anahtar kelimesi ile)
mixin ServiceHelper {
  Future<Either<Failure, T>> serve<T>(Future<T> Function() serviceCall) async {
    try {
      final response = await serviceCall();
      return Right(response);
    } on ServerException {
      return const Left(ServerFailure("Sunucu Hatası Oluştu"));
    } on NetworkException {
      return const Left(NetworkFailure("İnternet Bağlantınızı Kontrol Edin"));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
