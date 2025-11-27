import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/init/navigation/navigation_route.dart';
import 'core/init/navigation/navigation_service.dart';
import 'core/init/theme/dark_theme.dart';
import 'core/init/theme/light_theme.dart';
import 'core/constants/navigation/navigation_constants.dart';
import 'product/init/product_init.dart';
import 'features/settings/presentation/viewmodel/settings_view_model.dart';

class PratikApp extends StatelessWidget {
  const PratikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProductInit.providers,
      child: const _MaterialAppContent(),
    );
  }
}

class _MaterialAppContent extends StatelessWidget {
  const _MaterialAppContent();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<SettingsViewModel>().themeMode;
    return MaterialApp(
      title: 'Global Kelime',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Navigation
      navigatorKey: NavigationService.instance.navigatorKey,
      onGenerateRoute: NavigationRoute.instance.generateRoute,
      initialRoute: NavigationConstants.SPLASH,

      // --- TEMA KONFİGÜRASYONU ---
      theme: LightTheme.instance.themeData,
      darkTheme: DarkTheme.instance.themeData,
      themeMode: themeMode, // Dinamik tema
    );
  }
}
