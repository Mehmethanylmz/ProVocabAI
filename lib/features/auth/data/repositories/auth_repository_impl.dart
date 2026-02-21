import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // ── Helpers ───────────────────────────────────────────────────────────────

  AuthUserEntity _mapUser(User user) => AuthUserEntity(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
        isAnonymous: user.isAnonymous,
      );

  Either<Failure, AuthUserEntity> _handleFirebaseError(
      FirebaseAuthException e) {
    return Left(AuthFailure(e.message ?? e.code));
  }

  // ── IAuthRepository ───────────────────────────────────────────────────────

  @override
  Stream<AuthUserEntity?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(
            (user) => user != null ? _mapUser(user) : null,
          );

  @override
  AuthUserEntity? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? _mapUser(user) : null;
  }

  // ── Anonim (Misafir) ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthUserEntity>> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      return Right(_mapUser(credential.user!));
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  // ── Google ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthUserEntity>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null)
        return Left(AuthFailure('Google girişi iptal edildi'));

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return Right(_mapUser(userCredential.user!));
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  // ── Facebook ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthUserEntity>> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        return Left(AuthFailure(result.message ?? 'Facebook girişi başarısız'));
      }
      final credential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return Right(_mapUser(userCredential.user!));
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  // ── Apple ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthUserEntity>> signInWithApple() async {
    try {
      // Nonce oluştur
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);
      return Right(_mapUser(userCredential.user!));
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
