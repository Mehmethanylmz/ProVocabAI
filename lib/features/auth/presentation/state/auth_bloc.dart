// lib/features/auth/presentation/state/auth_bloc.dart
//
// FAZ 3 FIX:
//   F3-02: authStateChanges stream dinleme (mevcut — korunuyor)
//   F3-03: AuthAuthenticated → UserProfile bilgisi taşır (displayName, totalXp, weeklyXp)
//   F3-04: Sign-in sonrası → SyncManager.syncAll() + profil Firestore'dan çekilir

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pratikapp/firebase/auth/firebase_auth_service.dart';
import 'package:pratikapp/firebase/sync/sync_manager.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class GuestSignInRequested extends AuthEvent {
  const GuestSignInRequested();
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class AppleSignInRequested extends AuthEvent {
  const AppleSignInRequested();
}

class FacebookSignInRequested extends AuthEvent {
  const FacebookSignInRequested();
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// İlk yüklenme — auth durumu belirsiz
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// İşlem sürüyor
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// F3-03: Kimlik doğrulandı — profil verileri ile zenginleştirildi.
///
/// [user]    : FirebaseAuth User nesnesi (uid, email, photoURL)
/// [profile] : Firestore'dan çekilen profil (displayName, totalXp, weeklyXp, streakDays)
/// [isGuest] : Anonim kullanıcı mı
class AuthAuthenticated extends AuthState {
  final User user;
  final UserProfile profile;
  final bool isGuest;

  const AuthAuthenticated({
    required this.user,
    required this.profile,
    required this.isGuest,
  });

  /// Kolay erişim helper'ları
  String get uid => user.uid;
  String get displayName => profile.displayName;
  String? get photoUrl => profile.photoUrl;
  int get totalXp => profile.totalXp;
  int get weeklyXp => profile.weeklyXp;
  int get streakDays => profile.streakDays;

  @override
  List<Object?> get props =>
      [user.uid, isGuest, profile.totalXp, profile.weeklyXp];
}

/// Oturum kapalı
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Hata
class AuthError extends AuthState {
  final AuthFailure failure;
  final String message;
  const AuthError({required this.failure, required this.message});

  @override
  List<Object?> get props => [failure, message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required FirebaseAuthService authService,
    SyncManager? syncManager,
  })  : _authService = authService,
        _syncManager = syncManager,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<GuestSignInRequested>(_onGuestSignIn);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<AppleSignInRequested>(_onAppleSignIn);
    on<FacebookSignInRequested>(_onFacebookSignIn);
    on<SignOutRequested>(_onSignOut);
  }

  final FirebaseAuthService _authService;

  /// F3-04: SyncManager — sign-in sonrası Firestore ↔ Drift senkronizasyonu.
  /// null olabilir (test ortamında).
  final SyncManager? _syncManager;

  StreamSubscription<User?>? _authSubscription;

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    // Mevcut kullanıcıya bak
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _authService.fetchUserProfile(user);
      emit(AuthAuthenticated(
        user: user,
        profile: profile,
        isGuest: user.isAnonymous,
      ));

      // F3-04 + FAZ 7: Uygulama açılışında push + pull sync
      _syncManager?.syncAll().then((_) {
        _syncManager?.pullFromFirestore();
      }).catchError((_) {});
    } else {
      emit(const AuthUnauthenticated());
    }

    // Stream dinle — uygulama süresince
    await emit.forEach<User?>(
      _authService.authStateChanges,
      onData: (user) {
        if (user != null) {
          // Not: Stream callback'te async profil çekimi yapamıyoruz.
          // _postSignIn çağrıları sign-in handler'larında yapılıyor.
          // Stream sadece oturum durumunu izler.
          // Eğer mevcut state zaten AuthAuthenticated ise profili koru.
          final currentState = state;
          if (currentState is AuthAuthenticated &&
              currentState.user.uid == user.uid) {
            return currentState; // Profil zaten yüklü, tekrar emit etme
          }
          // Farklı kullanıcı veya henüz profil yüklenmemiş → fallback
          return AuthAuthenticated(
            user: user,
            profile: UserProfile.fromFirebaseUser(user),
            isGuest: user.isAnonymous,
          );
        }
        return const AuthUnauthenticated();
      },
      onError: (_, __) => const AuthUnauthenticated(),
    );
  }

  Future<void> _onGuestSignIn(
    GuestSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final cred = await _authService.signInAsGuest();
      await _postSignIn(cred.user!, emit);
    } on AuthException catch (e) {
      emit(AuthError(failure: e.failure, message: e.message));
    }
  }

  Future<void> _onGoogleSignIn(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final cred = await _authService.signInWithGoogle();
      await _postSignIn(cred.user!, emit);
    } on AuthException catch (e) {
      emit(AuthError(failure: e.failure, message: e.message));
    }
  }

  Future<void> _onAppleSignIn(
    AppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final cred = await _authService.signInWithApple();
      await _postSignIn(cred.user!, emit);
    } on AuthException catch (e) {
      emit(AuthError(failure: e.failure, message: e.message));
    }
  }

  Future<void> _onFacebookSignIn(
    FacebookSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final cred = await _authService.signInWithFacebook();
      await _postSignIn(cred.user!, emit);
    } on AuthException catch (e) {
      emit(AuthError(failure: e.failure, message: e.message));
    }
  }

  /// F3-04: Sign-out → Drift temizleme FirebaseAuthService içinde yapılır.
  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.signOut();
      // signOut() içinde _clearLocalUserData() çalışır
      emit(const AuthUnauthenticated());
    } on AuthException catch (e) {
      emit(AuthError(failure: e.failure, message: e.message));
    }
  }

  // ── F3-04: Post sign-in akışı ────────────────────────────────────────────

  /// Sign-in başarılı sonrası:
  /// 1. Firestore'dan profil çek (displayName, totalXp, weeklyXp)
  /// 2. SyncManager: push (local → Firestore) + pull (Firestore → local)
  /// 3. AuthAuthenticated state emit et
  ///
  /// FAZ 7: pullFromFirestore eklendi — sign-in sonrası remote progress'ler çekilir.
  Future<void> _postSignIn(User user, Emitter<AuthState> emit) async {
    // 1. Profil çek
    final profile = await _authService.fetchUserProfile(user);

    // 2. Sync: önce push (local bekleyenler), sonra pull (remote → local)
    // fire-and-forget — hata sign-in'i bloklamaz
    _syncManager?.syncAll().then((_) {
      // Push bitti → şimdi pull
      _syncManager?.pullFromFirestore();
    }).catchError((_) {});

    // 3. State emit
    emit(AuthAuthenticated(
      user: user,
      profile: profile,
      isGuest: user.isAnonymous,
    ));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
