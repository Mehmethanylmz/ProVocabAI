// lib/app.dart
//
// REWRITE: Legacy PratikApp (MultiProvider/ChangeNotifier) → Blueprint app.
//
// Silindi:
//   git rm lib/product/init/product_init.dart
//   (ProductInit.providers — Provider/ChangeNotifier)
//
// Yeni mimari:
//   - Provider YOK
//   - BlocProvider gerektiğinde ilgili route'ta açılır (getIt factory)
//   - NavigationService.instance.navigatorKey — FCM deep link + navigation
//   - ThemeMode: SettingsRepository'den (GetIt singleton)
//   - EasyLocalization: korunur (çeviri sistemi Blueprint dışı)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'core/constants/navigation/navigation_constants.dart';
import 'core/di/injection_container.dart';
import 'core/init/navigation/navigation_route.dart';
import 'core/init/navigation/navigation_service.dart';
import 'core/init/theme/dark_theme.dart';
import 'core/init/theme/light_theme.dart';
import 'core/init/lang/language_manager.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';

class PratikApp extends StatefulWidget {
  const PratikApp({super.key});

  @override
  State<PratikApp> createState() => _PratikAppState();
}

class _PratikAppState extends State<PratikApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final repo = getIt<SettingsRepositoryImpl>();
    final result = await repo.getThemeMode();
    if (mounted) {
      result.fold(
        (_) {}, // Failure → system default kullan
        (mode) => setState(() => _themeMode = mode),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: LanguageManager.instance.supportedLocales,
      path: LanguageManager.instance.assetPath,
      fallbackLocale: LanguageManager.instance.supportedLocales[1], // en-US
      child: Builder(
        builder: (ctx) => MaterialApp(
          title: 'ProVocabAI',
          debugShowCheckedModeBanner: false,

          // Localization
          localizationsDelegates: ctx.localizationDelegates,
          supportedLocales: ctx.supportedLocales,
          locale: ctx.locale,

          // Navigation — FCM deep link için navigatorKey zorunlu
          navigatorKey: NavigationService.instance.navigatorKey,
          onGenerateRoute: NavigationRoute.instance.generateRoute,
          initialRoute: NavigationConstants.SPLASH,

          // Theme
          theme: LightTheme.instance.themeData,
          darkTheme: DarkTheme.instance.themeData,
          themeMode: _themeMode,
        ),
      ),
    );
  }
}
