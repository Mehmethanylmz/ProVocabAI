import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/base/base_view_model.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/init/lang/language_manager.dart';

class SplashViewModel extends BaseViewModel {
  final ISettingsRepository _settingsRepo;

  SplashViewModel(this._settingsRepo);

  Future<void> initializeApp(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2));

    // 1. İlk Açılış Kontrolü
    final firstLaunchResult = await _settingsRepo.isFirstLaunch();
    bool isFirstLaunch =
        firstLaunchResult.fold((failure) => true, (success) => success);

    if (isFirstLaunch) {
      NavigationService.instance
          .navigateToPageClear(path: NavigationConstants.ONBOARDING);
      return;
    }

    // 2. Dil Yükleme
    final langResult = await _settingsRepo.getLanguageSettings();
    langResult.fold((l) {}, (settings) async {
      final sourceShort = settings['source'] ?? 'en';
      final longCode = LanguageManager.instance.getTtsLocale(sourceShort);
      final parts = longCode.split('-');
      if (context.mounted) {
        await context
            .setLocale(Locale(parts[0], parts.length > 1 ? parts[1] : ''));
      }
    });

    // 3. Direkt Ana Ekrana Git
    NavigationService.instance
        .navigateToPageClear(path: NavigationConstants.MAIN);
  }
}
