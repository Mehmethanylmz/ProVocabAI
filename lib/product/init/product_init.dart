import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../core/init/di/injection_container.dart';
import '../../core/init/lang/language_manager.dart';
import '../../features/dashboard/presentation/view_model/dashboard_view_model.dart';
import '../../features/main/presentation/view_model/main_view_model.dart';
import '../../features/onboarding/presentation/view_model/onboarding_view_model.dart';
import '../../features/settings/presentation/viewmodel/settings_view_model.dart';
import '../../features/study_zone/presentation/view_model/menu_view_model.dart';
import '../../features/study_zone/presentation/view_model/study_view_model.dart';

class ProductInit {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    await setupLocator();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider(create: (_) => locator<SettingsViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<MainViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<DashboardViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<StudyViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<MenuViewModel>()),
        ChangeNotifierProvider(create: (_) => locator<OnboardingViewModel>()),
      ];

  static EasyLocalization get localization => EasyLocalization(
        supportedLocales: LanguageManager.instance.supportedLocales,
        path: LanguageManager.instance.assetPath,
        fallbackLocale: LanguageManager.instance.supportedLocales.first,
        startLocale: LanguageManager.instance.supportedLocales[1],
        child: const SizedBox(),
      );
}
