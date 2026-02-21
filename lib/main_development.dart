import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app.dart';
import 'core/init/lang/language_manager.dart';
import 'firebase_options.dart';
import 'product/init/product_init.dart';

Future<void> main() async {
  await ProductInit.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    EasyLocalization(
      supportedLocales: LanguageManager.instance.supportedLocales,
      path: LanguageManager.instance.assetPath,
      fallbackLocale: LanguageManager.instance.supportedLocales[1], // en-US
      child: const PratikApp(),
    ),
  );
}
