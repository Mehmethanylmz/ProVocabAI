// test/firebase/auth/firebase_auth_service_test.dart
//
// T-15 Acceptance Criteria:
//   AC: Guest → UID oluştu (signInAnonymously çağrıldı)
//   AC: Google sign-in → isGuest=false
//   AC: signOut → currentUser null, logOut çağrıldı
//   AC: AuthException.failure doğru map ediliyor

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pratikapp/firebase/auth/firebase_auth_service.dart';

@GenerateNiceMocks([
  MockSpec<FacebookAuth>(),
  MockSpec<GoogleSignIn>(),
  MockSpec<GoogleSignInAccount>(),
  MockSpec<GoogleSignInAuthentication>(),
])
import 'firebase_auth_service_test.mocks.dart';

// ── Exception-throwing mock ───────────────────────────────────────────────────

class _ThrowingMockAuth extends MockFirebaseAuth {
  _ThrowingMockAuth({required this.code, this.message = ''});
  final String code;
  final String message;

  @override
  Future<UserCredential> signInAnonymously() async {
    throw FirebaseAuthException(code: code, message: message);
  }
}

void main() {
  // ── Guest sign-in ──────────────────────────────────────────────────────────

  group('signInAsGuest', () {
    test('AC: signInAnonymously — UID döner, isGuest=true', () async {
      final mockUser = MockUser(isAnonymous: true, uid: 'guest-uid-001');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final service = FirebaseAuthService(firebaseAuth: auth);

      final cred = await service.signInAsGuest();

      expect(cred.user?.uid, 'guest-uid-001');
      expect(service.isGuest, isTrue);
      expect(service.currentUser?.isAnonymous, isTrue);
    });

    test('AC: network hatası → AuthException.networkError', () async {
      final auth = _ThrowingMockAuth(
        code: 'network-request-failed',
        message: 'No network',
      );
      final service = FirebaseAuthService(firebaseAuth: auth);

      await expectLater(
        service.signInAsGuest(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.networkError,
          ),
        ),
      );
    });
  });

  // ── Google sign-in ─────────────────────────────────────────────────────────

  group('signInWithGoogle', () {
    /// GoogleSignIn mock helper: signIn() → account, authentication → tokens
    MockGoogleSignIn _mockGoogleSignIn() {
      final mockAuth = MockGoogleSignInAuthentication();
      when(mockAuth.accessToken).thenReturn('access-token');
      when(mockAuth.idToken).thenReturn('id-token');

      final mockAccount = MockGoogleSignInAccount();
      when(mockAccount.authentication).thenAnswer((_) async => mockAuth);

      final googleSignIn = MockGoogleSignIn();
      when(googleSignIn.signIn()).thenAnswer((_) async => mockAccount);
      return googleSignIn;
    }

    test('AC: Google sign-in — UserCredential döner', () async {
      final mockUser = MockUser(uid: 'google-uid-001');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        googleSignIn: _mockGoogleSignIn(),
      );

      final cred = await service.signInWithGoogle();
      expect(cred.user?.uid, isNotNull);
    });

    test('AC: Google sign-in sonrası isGuest=false', () async {
      final mockUser = MockUser(isAnonymous: false, uid: 'google-uid-002');
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final service = FirebaseAuthService(
        firebaseAuth: auth,
        googleSignIn: _mockGoogleSignIn(),
      );

      await service.signInWithGoogle();
      expect(service.isGuest, isFalse);
    });
  });

  // ── signOut ────────────────────────────────────────────────────────────────

  group('signOut', () {
    test('AC: signOut → currentUser null olur', () async {
      final mockUser = MockUser(uid: 'uid-123');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final googleSignIn = MockGoogleSignIn();
      when(googleSignIn.signOut()).thenAnswer((_) async => null);
      final mockFacebook = MockFacebookAuth();
      when(mockFacebook.logOut()).thenAnswer((_) async => {});

      final service = FirebaseAuthService(
        firebaseAuth: auth,
        googleSignIn: googleSignIn,
        facebookAuth: mockFacebook,
      );

      await service.signOut();
      expect(service.currentUser, isNull);
    });

    test('AC: signOut → FacebookAuth.logOut çağrılır', () async {
      final auth = MockFirebaseAuth(signedIn: true);
      final googleSignIn = MockGoogleSignIn();
      when(googleSignIn.signOut()).thenAnswer((_) async => null);
      final mockFacebook = MockFacebookAuth();
      when(mockFacebook.logOut()).thenAnswer((_) async => {});

      final service = FirebaseAuthService(
        firebaseAuth: auth,
        googleSignIn: googleSignIn,
        facebookAuth: mockFacebook,
      );

      await service.signOut();
      verify(mockFacebook.logOut()).called(1);
    });
  });

  // ── AuthFailure mapping (public mapAuthFailure) ───────────────────────────

  group('AuthFailure mapping', () {
    late FirebaseAuthService service;

    setUp(() {
      service = FirebaseAuthService(
        firebaseAuth: MockFirebaseAuth(),
        googleSignIn: MockGoogleSignIn(),
      );
    });

    final mappings = {
      'account-exists-with-different-credential':
          AuthFailure.accountExistsWithDifferentCredential,
      'invalid-credential': AuthFailure.invalidCredential,
      'user-disabled': AuthFailure.userDisabled,
      'operation-not-allowed': AuthFailure.operationNotAllowed,
      'email-already-in-use': AuthFailure.emailAlreadyInUse,
      'network-request-failed': AuthFailure.networkError,
      'some-unknown-code': AuthFailure.unknown,
    };

    mappings.forEach((code, expected) {
      test('$code → $expected', () {
        expect(service.mapAuthFailure(code), expected);
      });
    });
  });

  // ── authStateChanges stream ───────────────────────────────────────────────

  group('authStateChanges', () {
    test('AC: oturum açıkken stream User yayar', () async {
      final mockUser = MockUser(uid: 'stream-uid');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final service = FirebaseAuthService(firebaseAuth: auth);

      final user = await service.authStateChanges.first;
      expect(user?.uid, 'stream-uid');
    });

    test('AC: oturum kapalıyken stream null yayar', () async {
      final auth = MockFirebaseAuth(signedIn: false);
      final service = FirebaseAuthService(firebaseAuth: auth);

      final user = await service.authStateChanges.first;
      expect(user, isNull);
    });
  });
}
