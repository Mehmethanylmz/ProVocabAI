import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user_entity.dart';

abstract class IAuthRepository {
  /// Anlık oturum durumu stream'i
  Stream<AuthUserEntity?> get authStateChanges;

  /// Mevcut kullanıcı (senkron)
  AuthUserEntity? get currentUser;

  /// Anonim (misafir) giriş
  Future<Either<Failure, AuthUserEntity>> signInAnonymously();

  /// Google ile giriş
  Future<Either<Failure, AuthUserEntity>> signInWithGoogle();

  /// Facebook ile giriş
  Future<Either<Failure, AuthUserEntity>> signInWithFacebook();

  /// Apple ile giriş
  Future<Either<Failure, AuthUserEntity>> signInWithApple();

  /// Çıkış
  Future<Either<Failure, void>> signOut();
}
