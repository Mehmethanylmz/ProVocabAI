// lib/features/auth/presentation/state/auth_bloc.dart
//
// T-15: AuthBloc — FirebaseAuthService üzerinden tüm auth akışları
// REPLACES: auth_view_model.dart (Provider/ChangeNotifier)
//
// git rm lib/features/auth/presentation/viewmodel/auth_view_model.dart

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pratikapp/firebase/auth/firebase_auth_service.dart';

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

/// Kimlik doğrulandı
class AuthAuthenticated extends AuthState {
  final User user;
  final bool isGuest;
  const AuthAuthenticated({required this.user, required this.isGuest});

  @override
  List<Object?> get props => [user.uid, isGuest];
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
  AuthBloc({required FirebaseAuthService authService})
      : _authService = authService,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<GuestSignInRequested>(_onGuestSignIn);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<AppleSignInRequested>(_onAppleSignIn);
    on<FacebookSignInRequested>(_onFacebookSignIn);
    on<SignOutRequested>(_onSignOut);
  }

  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    // Mevcut kullanıcıya bak
    final user = _authService.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user: user, isGuest: user.isAnonymous));
    } else {
      emit(const AuthUnauthenticated());
    }

    // Stream dinle — uygulama süresince
    await emit.forEach<User?>(
      _authService.authStateChanges,
      onData: (user) => user != null
          ? AuthAuthenticated(user: user, isGuest: user.isAnonymous)
          : const AuthUnauthenticated(),
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
      emit(AuthAuthenticated(
        user: cred.user!,
        isGuest: true,
      ));
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
      emit(AuthAuthenticated(
        user: cred.user!,
        isGuest: false,
      ));
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
      emit(AuthAuthenticated(
        user: cred.user!,
        isGuest: false,
      ));
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
      emit(AuthAuthenticated(
        user: cred.user!,
        isGuest: false,
      ));
    } on AuthException catch (e) {
      emit(AuthError(failure: e.failure, message: e.message));
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.signOut();
      emit(const AuthUnauthenticated());
    } on AuthException catch (e) {
      emit(AuthError(failure: e.failure, message: e.message));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
