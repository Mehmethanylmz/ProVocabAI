import '../../../../core/base/base_view_model.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthViewModel extends BaseViewModel {
  final IAuthRepository _authRepo;

  AuthViewModel(this._authRepo) {
    // Oturum durumu değişikliklerini dinle
    _authRepo.authStateChanges.listen((user) {
      _currentUser = user;
      _status =
          user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  AuthUserEntity? _currentUser;
  AuthUserEntity? get currentUser => _currentUser;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoggedIn => _authRepo.currentUser != null;

  // ── Giriş yöntemleri ─────────────────────────────────────────────────────

  Future<bool> signInAnonymously() => _signIn(
        () => _authRepo.signInAnonymously(),
      );

  Future<bool> signInWithGoogle() => _signIn(
        () => _authRepo.signInWithGoogle(),
      );

  Future<bool> signInWithFacebook() => _signIn(
        () => _authRepo.signInWithFacebook(),
      );

  Future<bool> signInWithApple() => _signIn(
        () => _authRepo.signInWithApple(),
      );

  Future<bool> signOut() async {
    changeLoading();
    _errorMessage = '';
    final result = await _authRepo.signOut();
    changeLoading();
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) => true,
    );
  }

  // ── Private helper ────────────────────────────────────────────────────────

  Future<bool> _signIn(
    Future<dynamic> Function() signInMethod,
  ) async {
    _status = AuthStatus.loading;
    _errorMessage = '';
    changeLoading();
    notifyListeners();

    final result = await signInMethod();
    changeLoading();

    return result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (user) {
        _currentUser = user as AuthUserEntity;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      },
    );
  }

  /// displayName yoksa email'den veya uid'den oluştur
  String get displayName {
    final user = _currentUser;
    if (user == null) return 'Misafir';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    return user.isAnonymous ? 'Misafir' : 'Kullanıcı';
  }
}
