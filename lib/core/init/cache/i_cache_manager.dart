import 'package:dartz/dartz.dart';
import '../../error/failures.dart';
import '../../constants/enum/cache_keys.dart';

/// Önbellek işlemlerinin soyut arayüzü.
abstract class ICacheManager {
  Future<Either<Failure, void>> setString(CacheKeys key, String value);
  Future<Either<Failure, void>> setBool(CacheKeys key, bool value);
  Future<Either<Failure, void>> setInt(CacheKeys key, int value);

  Either<Failure, String?> getString(CacheKeys key);
  Either<Failure, bool?> getBool(CacheKeys key);
  Either<Failure, int?> getInt(CacheKeys key);

  Future<Either<Failure, void>> remove(CacheKeys key);
  Future<Either<Failure, void>> clearAll();
  bool containsKey(CacheKeys key);
}
