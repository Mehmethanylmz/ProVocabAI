// lib/app.dart
//
// FIX: Theme anlık değişim — SettingsRepositoryImpl.themeStream dinleniyor
// FIX: AuthBloc app seviyesinde → DashboardBloc UID değişince reload
// FIX: Main route'ta MultiBlocProvider ile AuthBloc + DashboardBloc sağlanıyor

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/navigation/navigation_constants.dart';
import 'core/di/injection_container.dart';
import 'core/init/navigation/navigation_route.dart';
import 'core/init/navigation/navigation_service.dart';
import 'core/init/theme/dark_theme.dart';
import 'core/init/theme/light_theme.dart';
import 'core/init/lang/language_manager.dart';
import 'features/auth/presentation/state/auth_bloc.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';

class PratikApp extends StatefulWidget {
  const PratikApp({super.key});

  @override
  State<PratikApp> createState() => _PratikAppState();
}

class _PratikAppState extends State<PratikApp> {
  ThemeMode _themeMode = ThemeMode.system;
  StreamSubscription<ThemeMode>? _themeSub;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthStarted());
    _initTheme();
  }

  Future<void> _initTheme() async {
    final repo = getIt<SettingsRepositoryImpl>();

    // İlk değeri yükle
    final result = await repo.getThemeMode();
    if (mounted) {
      result.fold((_) {}, (mode) => setState(() => _themeMode = mode));
    }

    // Stream'i dinle — SettingsBloc kaydettiğinde anlık güncelle
    _themeSub = repo.themeStream.listen((mode) {
      if (mounted) setState(() => _themeMode = mode);
    });
  }

  @override
  void dispose() {
    _themeSub?.cancel();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: EasyLocalization(
        supportedLocales: LanguageManager.instance.supportedLocales,
        path: LanguageManager.instance.assetPath,
        fallbackLocale: LanguageManager.instance.supportedLocales[1],
        child: Builder(
          builder: (ctx) => MaterialApp(
            title: 'ProVocabAI',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: ctx.locale,
            navigatorKey: NavigationService.instance.navigatorKey,
            onGenerateRoute: NavigationRoute.instance.generateRoute,
            initialRoute: NavigationConstants.SPLASH,
            theme: LightTheme.instance.themeData,
            darkTheme: DarkTheme.instance.themeData,
            themeMode: _themeMode,
          ),
        ),
      ),
    );
  }
}
