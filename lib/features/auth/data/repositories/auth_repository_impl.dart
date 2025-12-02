import 'package:dartz/dartz.dart';
import '../../../../core/base/service_helper.dart';
import '../../../../core/constants/enum/app_enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/init/network/network_manager.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl with ServiceHelper implements IAuthRepository {
  final NetworkManager _networkManager = NetworkManager.instance;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, UserEntity>> login(
      String email, String password) async {
    return await serve<UserEntity>(() async {
      // 1. API İsteği At
      final response = await _networkManager.send<UserModel>(
        '/auth/login',
        type: HttpTypes.POST,
        data: {'email': email, 'password': password},
        parseModel: (json) => UserModel.fromJson(json),
      );

      // 2. Token ve Kullanıcıyı Telefona Kaydet
      if (response != null) {
        await _localDataSource.saveUser(response);
        return response;
      } else {
        throw Exception("Kullanıcı verisi alınamadı.");
      }
    });
  }

  @override
  Future<Either<Failure, UserEntity>> register(
      String name, String email, String password) async {
    return await serve<UserEntity>(() async {
      final response = await _networkManager.send<UserModel>(
        '/auth/register',
        type: HttpTypes.POST,
        data: {'name': name, 'email': email, 'password': password},
        parseModel: (json) => UserModel.fromJson(json),
      );

      if (response != null) {
        await _localDataSource.saveUser(response);
        return response;
      } else {
        throw Exception("Kayıt işlemi başarısız.");
      }
    });
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    return await serve<void>(() async {
      await _networkManager.send<dynamic>(
        '/auth/forgot-password',
        type: HttpTypes.POST,
        data: {'email': email},
        parseModel: (json) => json,
      );
    });
  }

  @override
  Future<Either<Failure, void>> logout() async {
    // API'ye logout isteği atılabilir ama şart değil, yerel veriyi silmek yeterli.
    await _localDataSource.clearUser();
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    final hasToken = _localDataSource.hasToken();
    return Right(hasToken);
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    final user = _localDataSource.getUser();
    return Right(user);
  }
}
