import '../../../../core/base/base_view_model.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';

class AuthViewModel extends BaseViewModel {
  final IAuthRepository _authRepository;

  AuthViewModel(this._authRepository);

  // Kullanıcı bilgisi
  UserEntity? _currentUser;
  UserEntity? get currentUser => _currentUser;

  // Hata Mesajı (UI'da snackbar göstermek için)
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> login(String email, String password) async {
    changeLoading(); // Loading başlat
    _errorMessage = null;

    final result = await _authRepository.login(email, password);

    result.fold(
      (failure) {
        // Hata Durumu
        _errorMessage = failure.message;
        notifyListeners(); // UI'ı güncelle ki hatayı görsün
      },
      (user) {
        // Başarı Durumu
        _currentUser = user;
        NavigationService.instance
            .navigateToPageClear(path: NavigationConstants.MAIN);
      },
    );
    changeLoading(); // Loading bitir
  }

  Future<void> register(String name, String email, String password) async {
    changeLoading();
    _errorMessage = null;

    final result = await _authRepository.register(name, email, password);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
      (user) {
        // Kayıt başarılı ise direkt giriş yapabilir veya email doğrulamaya atabilirsin.
        // Biz direkt ana sayfaya alalım.
        _currentUser = user;
        NavigationService.instance
            .navigateToPageClear(path: NavigationConstants.MAIN);
      },
    );
    changeLoading();
  }

  Future<void> forgotPassword(String email) async {
    changeLoading();
    _errorMessage = null;

    final result = await _authRepository.forgotPassword(email);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (_) {
        // Başarılı, UI'da bir dialog gösterebiliriz.
        // ViewModel içinde Context olmadığı için bunu UI tarafında dinlemek daha doğru
        // ama basitlik için success state tutabiliriz.
        _errorMessage =
            "Sıfırlama bağlantısı gönderildi."; // Hata değil bilgi olarak kullanıyoruz
      },
    );
    changeLoading();
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    NavigationService.instance
        .navigateToPageClear(path: NavigationConstants.LOGIN);
  }
}
