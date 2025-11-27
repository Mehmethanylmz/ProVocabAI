import 'package:flutter/material.dart';
import '../../../../core/base/base_view_model.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';

class SplashViewModel extends BaseViewModel {
  final ISettingsRepository _settingsRepo;
  // İleride buraya AuthRepository de eklenecek:
  // final IAuthRepository _authRepo;

  SplashViewModel(this._settingsRepo) {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Simüle edilmiş yükleme süresi (Logo görünsün diye)
    // Gerçek hayatta burada API'den config çekme, token yenileme işlemleri yapılır.
    await Future.delayed(const Duration(seconds: 2));

    // 2. İlk Açılış Kontrolü
    final result = await _settingsRepo.isFirstLaunch();

    bool isFirstLaunch = result.fold(
        (failure) =>
            true, // Hata varsa (DB okunamadı vs.), güvenli davran ve Onboarding göster.
        (success) => success // Başarılıysa veritabanındaki değeri al.
        );

    // 3. Yönlendirme Kararı
    if (isFirstLaunch) {
      NavigationService.instance
          .navigateToPageClear(path: NavigationConstants.ONBOARDING);
    } else {
      // BURASI İLERİDE DEĞİŞECEK:
      // if (hasValidToken) -> MAIN
      // else -> LOGIN
      NavigationService.instance
          .navigateToPageClear(path: NavigationConstants.MAIN);
    }
  }
}
