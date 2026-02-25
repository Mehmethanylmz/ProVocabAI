// lib/firebase/auth/firebase_auth_service.dart
//
// T-15: FirebaseAuthService Wrapper
// Blueprint: signInAsGuest, signInWithGoogle (linkWithCredential guard),
//            signInWithApple, signInWithFacebook, signOut, currentUser stream
//
// REFACTOR: login_view.dart → bu service'e delege eder
// Test: Guest → UID oluştu | Google link → aynı UID | linkWithCredential fail
//        → account-exists-with-different-credential hatası handle edilir

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase Auth hata kodları
enum AuthFailure {
  accountExistsWithDifferentCredential,
  invalidCredential,
  userDisabled,
  operationNotAllowed,
  emailAlreadyInUse,
  networkError,
  unknown,
}

class AuthException implements Exception {
  final AuthFailure failure;
  final String message;
  const AuthException(this.failure, this.message);

  @override
  String toString() => 'AuthException($failure): $message';
}

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  // ── Current user stream ───────────────────────────────────────────────────

  /// Kullanıcı oturum değişikliklerini dinler.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Anlık kullanıcı (nullable).
  User? get currentUser => _auth.currentUser;

  /// Kullanıcı anonim mi?
  bool get isGuest =>
      _auth.currentUser != null && (_auth.currentUser!.isAnonymous);

  // ── Guest sign-in ─────────────────────────────────────────────────────────

  /// Anonim giriş — her çağrıda UID sabit kalır (session boyunca).
  Future<UserCredential> signInAsGuest() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
    }
  }

  // ── Google sign-in / link ─────────────────────────────────────────────────

  /// Google ile giriş. Anonim kullanıcıysa önce `linkWithCredential` dener,
  /// başarısız olursa (`account-exists-with-different-credential`) mevcut
  /// Google hesabıyla `signInWithCredential` yapar.
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(
            AuthFailure.operationNotAllowed, 'Google sign-in cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _signInOrLink(credential);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
    }
  }

  // ── Apple sign-in / link ──────────────────────────────────────────────────

  /// Apple ile giriş. iOS'ta zorunlu, Android'de opsiyonel.
  Future<UserCredential> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);

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
      return await _signInOrLink(oauthCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException(
            AuthFailure.operationNotAllowed, 'Apple sign-in cancelled');
      }
      throw AuthException(AuthFailure.unknown, e.message);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
    }
  }

  // ── Facebook sign-in / link ───────────────────────────────────────────────

  /// Facebook ile giriş.
  Future<UserCredential> signInWithFacebook() async {
    try {
      final loginResult = await _facebookAuth.login();
      if (loginResult.status != LoginStatus.success) {
        throw const AuthException(
            AuthFailure.operationNotAllowed, 'Facebook sign-in cancelled');
      }
      final facebookCredential = FacebookAuthProvider.credential(
        loginResult.accessToken!.tokenString,
      );
      return await _signInOrLink(facebookCredential);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  /// Tüm sağlayıcılardan çıkış.
  /// Not: Future.wait kullanılmıyor — MockGoogleSignIn.signOut() return type
  /// Future<GoogleSignInAccount?> olduğundan Future.wait<void> ile uyumsuz.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await _facebookAuth.logOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Anonim kullanıcıysa link, değilse doğrudan sign-in dener.
  ///
  /// `account-exists-with-different-credential`:
  ///   → Mevcut oturumu kapat, credential ile yeniden giriş yap.
  ///   → UID değişir; çağıran kod kullanıcıyı uyarmalıdır.
  Future<UserCredential> _signInOrLink(AuthCredential credential) async {
    if (isGuest) {
      try {
        return await _auth.currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential' ||
            e.code == 'credential-already-in-use') {
          // Guest'i koru — mevcut hesapla sign-in
          return await _auth.signInWithCredential(credential);
        }
        throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
      }
    }
    return await _auth.signInWithCredential(credential);
  }

  AuthFailure mapAuthFailure(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return AuthFailure.accountExistsWithDifferentCredential;
      case 'invalid-credential':
        return AuthFailure.invalidCredential;
      case 'user-disabled':
        return AuthFailure.userDisabled;
      case 'operation-not-allowed':
        return AuthFailure.operationNotAllowed;
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse;
      case 'network-request-failed':
        return AuthFailure.networkError;
      default:
        return AuthFailure.unknown;
    }
  }

  /// Apple nonce için 32 byte random string
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
