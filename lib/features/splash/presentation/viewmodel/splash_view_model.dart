import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/base/base_view_model.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';
import '../../../study_zone/domain/repositories/i_word_repository.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/init/lang/language_manager.dart';

class SplashViewModel extends BaseViewModel {
  final ISettingsRepository _settingsRepo;
  final IWordRepository _wordRepo;
  final IAuthRepository _authRepo;

  SplashViewModel(this._settingsRepo, this._wordRepo, this._authRepo);

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

    // 2. DB Boşluk Kontrolü — kelimeler hiç yüklenmemişse yükle
    // (Yeniden kurulum, veri silme veya önceki sürümden geçiş durumları)
    final wordCountResult = await _wordRepo.getWordCount();
    final wordCount = wordCountResult.fold((l) => 0, (count) => count);

    if (wordCount == 0) {
      changeLoading();
      final langResult = await _settingsRepo.getLanguageSettings();
      String nativeLang = 'en';
      String targetLang = 'tr';
      langResult.fold((l) {}, (settings) {
        nativeLang = settings['source'] ?? 'en';
        targetLang = settings['target'] ?? 'tr';
      });

      // Asset'ten kelime veritabanını yükle
      await _wordRepo.downloadInitialContent(nativeLang, targetLang);
      changeLoading();
    }

    // 3. Dil Yükleme
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

    // 4. Auth kontrolü → LOGIN veya MAIN
    if (!context.mounted) return;
    final isLoggedIn = _authRepo.currentUser != null;
    NavigationService.instance.navigateToPageClear(
      path: isLoggedIn ? NavigationConstants.MAIN : NavigationConstants.LOGIN,
    );
  }
}
