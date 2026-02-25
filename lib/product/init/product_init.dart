// lib/product/init/product_init.dart
//
// T-08 STUB — Provider bağımlılığı kaldırıldı.
// Sprint 2 T-10: SplashBloc._onAppStarted ile dolacak.
// Bu dosya derleme hatasını engeller.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class ProductInit {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // TODO T-10: AppDatabase.init(), DatasetService.seedWordsIfNeeded() buraya taşınacak
    // TODO T-10: GetIt service locator setup buraya taşınacak
  }
}
