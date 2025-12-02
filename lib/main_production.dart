import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';
import 'core/init/config/app_environment.dart';
import 'core/init/lang/language_manager.dart';
import 'product/init/product_init.dart';

Future<void> main() async {
  AppEnvironment.setup(AppEnvironmentConfig.production);

  await ProductInit.init();

  runApp(
    EasyLocalization(
      supportedLocales: LanguageManager.instance.supportedLocales,
      path: LanguageManager.instance.assetPath,
      fallbackLocale: LanguageManager.instance.supportedLocales[1],
      child: const PratikApp(),
    ),
  );
}
