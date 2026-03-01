// lib/firebase/auth/firebase_auth_service.dart
//
// T-15: FirebaseAuthService Wrapper
// FAZ 3 FIX:
//   F3-01: signOut() → Drift kullanıcı verisi temizlenir (words hariç)
//   F3-03: fetchUserProfile() → Firestore'dan profil verileri çeker
//   F3-04: postSignInSync() → SyncManager.syncAll() çağrısı

import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../database/app_database.dart';

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

/// Firestore'dan çekilen profil verisi.
/// AuthBloc state'ine aktarılır.
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isAnonymous;
  final int totalXp;
  final int weeklyXp;
  final int streakDays;
  final String? lastActiveDate;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.isAnonymous,
    this.totalXp = 0,
    this.weeklyXp = 0,
    this.streakDays = 0,
    this.lastActiveDate,
  });

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: (data['displayName'] as String?) ?? 'Kullanıcı',
      email: (data['email'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      isAnonymous: (data['isAnonymous'] as bool?) ?? false,
      totalXp: (data['totalXp'] as num?)?.toInt() ?? 0,
      weeklyXp: (data['weeklyXp'] as num?)?.toInt() ?? 0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      lastActiveDate: data['lastActiveDate'] as String?,
    );
  }

  /// FirebaseAuth User'dan fallback profil oluştur (Firestore erişilemezse)
  factory UserProfile.fromFirebaseUser(User user) {
    return UserProfile(
      uid: user.uid,
      displayName:
          user.displayName ?? (user.isAnonymous ? 'Misafir' : 'Kullanıcı'),
      email: user.email ?? '',
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
  }
}

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
    FirebaseFirestore? firestore,
    AppDatabase? database,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _db = database;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;
  final FirebaseFirestore _firestore;

  /// F3-01: Drift DB referansı — signOut'ta tablo temizleme için.
  /// null olabilir (test ortamında). null ise temizleme atlanır.
  final AppDatabase? _db;

  // ── Current user stream ───────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isGuest =>
      _auth.currentUser != null && (_auth.currentUser!.isAnonymous);

  // ── Guest sign-in ─────────────────────────────────────────────────────────

  Future<UserCredential> signInAsGuest() async {
    try {
      final cred = await _auth.signInAnonymously();
      await _writeProfileIfNeeded(cred.user);
      return cred;
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
    }
  }

  // ── Google sign-in / link ─────────────────────────────────────────────────

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
      final cred = await _signInOrLink(credential);
      await _writeProfileIfNeeded(cred.user);
      return cred;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
    }
  }

  // ── Apple sign-in / link ──────────────────────────────────────────────────

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
      final cred = await _signInOrLink(oauthCredential);
      await _writeProfileIfNeeded(cred.user);
      return cred;
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
      final cred = await _signInOrLink(facebookCredential);
      await _writeProfileIfNeeded(cred.user);
      return cred;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
    }
  }

  // ── Sign out (F3-01: Drift temizleme) ─────────────────────────────────────

  /// Çıkış yapar ve kullanıcıya özel lokal verileri temizler.
  ///
  /// Temizlenen tablolar: progress, sessions, reviewEvents, dailyPlans, syncQueue
  /// Korunan tablo: words (kelime veritabanı herkese ortak)
  Future<void> signOut() async {
    try {
      // F3-01: Önce lokal verileri temizle (auth hala geçerli → UID ile log tutulabilir)
      await _clearLocalUserData();

      await _auth.signOut();
      await _googleSignIn.signOut();
      await _facebookAuth.logOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
    }
  }

  // ── F3-01: Drift tablo temizleme ──────────────────────────────────────────

  /// Kullanıcıya özel tüm lokal verileri siler.
  /// `words` tablosu KORUNUR — kelime veritabanı herkese ortaktır.
  Future<void> _clearLocalUserData() async {
    if (_db == null) return;

    try {
      await _db.transaction(() async {
        await _db.delete(_db.progress).go();
        await _db.delete(_db.sessions).go();
        await _db.delete(_db.reviewEvents).go();
        await _db.delete(_db.dailyPlans).go();
        await _db.delete(_db.syncQueue).go();
      });
    } catch (e) {
      // Temizleme hatası sign-out'u bloklamaz
      assert(() {
        // ignore: avoid_print
        print('[FirebaseAuthService] _clearLocalUserData error: $e');
        return true;
      }());
    }
  }

  // ── F3-03: Firestore profil çekme ─────────────────────────────────────────

  /// Firestore'dan kullanıcı profil bilgilerini çeker.
  ///
  /// Erişim başarısızsa FirebaseAuth User'dan fallback profil döner.
  /// Bu metod sign-in sonrası AuthBloc tarafından çağrılır.
  Future<UserProfile> fetchUserProfile(User user) async {
    try {
      final ref = _firestore.doc('users/${user.uid}/profile/main');
      final snap = await ref.get();

      if (snap.exists && snap.data() != null) {
        return UserProfile.fromFirestore(user.uid, snap.data()!);
      }
    } catch (e) {
      // Firestore erişim hatası — fallback profil kullan
      assert(() {
        // ignore: avoid_print
        print('[FirebaseAuthService] fetchUserProfile error: $e');
        return true;
      }());
    }

    // Fallback: FirebaseAuth User'dan temel profil
    return UserProfile.fromFirebaseUser(user);
  }

  // ── Private: Firestore profile write ──────────────────────────────────────

  Future<void> _writeProfileIfNeeded(User? user) async {
    if (user == null) return;

    final ref = _firestore.doc('users/${user.uid}/profile/main');

    try {
      final snap = await ref.get();

      if (!snap.exists) {
        await ref.set({
          'uid': user.uid,
          'displayName': _resolveDisplayName(user),
          'email': user.email ?? '',
          'isAnonymous': user.isAnonymous,
          'photoUrl': user.photoURL ?? '',
          'fcmToken': '',
          'totalXp': 0,
          'weeklyXp': 0,
          'streakDays': 0,
          'lastActiveDate': _todayString(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.set(
          {
            'uid': user.uid,
            'displayName': _resolveDisplayName(user),
            'email': user.email ?? '',
            'isAnonymous': user.isAnonymous,
            'photoUrl': user.photoURL ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[FirebaseAuthService] _writeProfileIfNeeded error: $e');
        return true;
      }());
    }
  }

  String _resolveDisplayName(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.isAnonymous) return 'Misafir';
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    return 'Kullanıcı';
  }

  String _todayString() => DateTime.now().toIso8601String().substring(0, 10);

  // ── Private: sign-in or link ──────────────────────────────────────────────

  Future<UserCredential> _signInOrLink(AuthCredential credential) async {
    if (isGuest) {
      try {
        return await _auth.currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential' ||
            e.code == 'credential-already-in-use') {
          return await _auth.signInWithCredential(credential);
        }
        throw AuthException(mapAuthFailure(e.code), e.message ?? e.code);
      }
    }
    return await _auth.signInWithCredential(credential);
  }

  // ── Public: hata kodu eşleme ──────────────────────────────────────────────

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

  // ── Private: Apple nonce ──────────────────────────────────────────────────

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
