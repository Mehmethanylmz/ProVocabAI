import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/enum/cache_keys.dart';
import '../../error/failures.dart';
import 'i_cache_manager.dart';

class CacheManager implements ICacheManager {
  final SharedPreferences _preferences;

  CacheManager(this._preferences);

  @override
  Future<Either<Failure, void>> setString(CacheKeys key, String value) async {
    try {
      await _preferences.setString(key.name, value);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setBool(CacheKeys key, bool value) async {
    try {
      await _preferences.setBool(key.name, value);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setInt(CacheKeys key, int value) async {
    try {
      await _preferences.setInt(key.name, value);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Either<Failure, String?> getString(CacheKeys key) {
    try {
      return Right(_preferences.getString(key.name));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Either<Failure, bool?> getBool(CacheKeys key) {
    try {
      return Right(_preferences.getBool(key.name));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Either<Failure, int?> getInt(CacheKeys key) {
    try {
      return Right(_preferences.getInt(key.name));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> remove(CacheKeys key) async {
    try {
      await _preferences.remove(key.name);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    try {
      await _preferences.clear();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  bool containsKey(CacheKeys key) => _preferences.containsKey(key.name);
}
