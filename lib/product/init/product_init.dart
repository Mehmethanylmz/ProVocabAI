import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../core/init/di/injection_container.dart';
import '../../core/init/lang/language_manager.dart';
import '../../features/main/presentation/view_model/main_view_model.dart';
import '../../features/settings/presentation/viewmodel/settings_view_model.dart';
import '../../features/dashboard/presentation/view_model/dashboard_view_model.dart';
import '../../features/study_zone/presentation/view_model/study_view_model.dart';
import '../../features/study_zone/presentation/view_model/menu_view_model.dart';
import '../../features/onboarding/presentation/view_model/onboarding_view_model.dart';
import 'database/ProductDatabaseManager';

class ProductInit {
  // 1. Uygulama Başlamadan Önceki Hazırlıklar
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    // Dependency Injection
    await setupLocator();

    // Database
    await ProductDatabaseManager.instance.populateDatabase();

    // UI Kısıtlamaları
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // 2. Global Provider Listesi (App.dart'ı temiz tutmak için)
  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider(create: (_) => locator<SettingsViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<MainViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<DashboardViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<StudyViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<MenuViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<OnboardingViewModel>()),
      ];

  // 3. Localization Konfigürasyonu
  static EasyLocalization get localization => EasyLocalization(
        supportedLocales: LanguageManager.instance.supportedLocales,
        path: LanguageManager.instance.assetPath,
        fallbackLocale:
            LanguageManager.instance.supportedLocales.first, // en-US
        startLocale:
            LanguageManager.instance.supportedLocales[1], // tr-TR (Opsiyonel)
        // ignore: missing_required_param
        child: const SizedBox(), // Bu child App.dart içinde ezilecek
      );
}
