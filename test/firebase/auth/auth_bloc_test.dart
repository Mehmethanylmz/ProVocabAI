// test/firebase/auth/auth_bloc_test.dart
//
// T-15: AuthBloc Unit Tests
// Çalıştır: flutter test test/firebase/auth/auth_bloc_test.dart

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pratikapp/features/auth/presentation/state/auth_bloc.dart';
import 'package:pratikapp/firebase/auth/firebase_auth_service.dart';

@GenerateMocks([FirebaseAuthService])
import 'auth_bloc_test.mocks.dart';

void main() {
  late MockFirebaseAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockFirebaseAuthService();
    // authStateChanges default: boş stream
    when(mockAuthService.authStateChanges)
        .thenAnswer((_) => const Stream.empty());
    when(mockAuthService.currentUser).thenReturn(null);
    when(mockAuthService.isGuest).thenReturn(false);
  });

  // ── AuthStarted ───────────────────────────────────────────────────────────

  group('AuthStarted', () {
    blocTest<AuthBloc, AuthState>(
      'currentUser null → AuthUnauthenticated',
      build: () {
        when(mockAuthService.currentUser).thenReturn(null);
        when(mockAuthService.authStateChanges)
            .thenAnswer((_) => Stream.value(null));
        return AuthBloc(authService: mockAuthService);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'currentUser mevcut → AuthAuthenticated',
      build: () {
        final user = MockUser(uid: 'uid-123');
        when(mockAuthService.currentUser).thenReturn(user as User?);
        when(mockAuthService.isGuest).thenReturn(false);
        when(mockAuthService.authStateChanges)
            .thenAnswer((_) => Stream.value(user));
        return AuthBloc(authService: mockAuthService);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        isA<AuthAuthenticated>().having((s) => s.isGuest, 'isGuest', false),
      ],
    );
  });

  // ── GuestSignInRequested ──────────────────────────────────────────────────

  group('GuestSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'AC: Guest giriş başarılı → [AuthLoading, AuthAuthenticated(isGuest=true)]',
      build: () {
        final user = MockUser(isAnonymous: true, uid: 'guest-uid');
        final cred = MockUserCredential(user as User);
        when(mockAuthService.signInAsGuest()).thenAnswer((_) async => cred);
        return AuthBloc(authService: mockAuthService);
      },
      act: (bloc) => bloc.add(const GuestSignInRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having((s) => s.isGuest, 'isGuest', isTrue),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AC: Guest giriş başarısız → [AuthLoading, AuthError(networkError)]',
      build: () {
        when(mockAuthService.signInAsGuest()).thenThrow(
          const AuthException(AuthFailure.networkError, 'network error'),
        );
        return AuthBloc(authService: mockAuthService);
      },
      act: (bloc) => bloc.add(const GuestSignInRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>()
            .having((s) => s.failure, 'failure', AuthFailure.networkError),
      ],
    );
  });

  // ── GoogleSignInRequested ─────────────────────────────────────────────────

  group('GoogleSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'AC: Google giriş başarılı → AuthAuthenticated(isGuest=false)',
      build: () {
        final user = MockUser(uid: 'google-uid');
        final cred = MockUserCredential(user as User);
        when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => cred);
        return AuthBloc(authService: mockAuthService);
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>().having((s) => s.isGuest, 'isGuest', isFalse),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AC: Google iptal → AuthError(operationNotAllowed)',
      build: () {
        when(mockAuthService.signInWithGoogle()).thenThrow(
          const AuthException(AuthFailure.operationNotAllowed, 'cancelled'),
        );
        return AuthBloc(authService: mockAuthService);
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>().having(
            (s) => s.failure, 'failure', AuthFailure.operationNotAllowed),
      ],
    );
  });

  // ── SignOutRequested ──────────────────────────────────────────────────────

  group('SignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'AC: signOut başarılı → [AuthLoading, AuthUnauthenticated]',
      build: () {
        when(mockAuthService.signOut()).thenAnswer((_) async {});
        return AuthBloc(authService: mockAuthService);
      },
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );
  });
}

// ── MockUserCredential helper ─────────────────────────────────────────────────

class MockUserCredential extends Mock implements UserCredential {
  final User _user;
  MockUserCredential(this._user);

  @override
  User? get user => _user;
}
