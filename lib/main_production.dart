// lib/main_production.dart
//
// Production entry point.
// - FlutterError.onError → Crashlytics (uncaught Flutter errors)
// - PlatformDispatcher → Crashlytics (async errors)
// - EasyLocalization aktif (F2-03)
// - MobileAds.initialize() (F2-03)
// - FCM background handler (F2-02)
// - BLoC observer YOK (production'da gereksiz log)

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/init/navigation/navigation_service.dart';
import 'core/services/dataset_service.dart';
import 'firebase/messaging/fcm_service.dart';
import 'firebase_options.dart';

// ── FCM Background Handler — top-level, @pragma zorunlu ──────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate: UI işlemi yapma, sadece log.
  debugPrint('[FCM BG] messageId: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── EasyLocalization — runApp'tan ÖNCE zorunlu (F2-03) ──────────────────
  await EasyLocalization.ensureInitialized();

  // ── Orientation lock ────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase ────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── FCM Background handler — Firebase.initializeApp'tan SONRA (F2-02) ───
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── Crashlytics: Flutter hatalarını yakala ──────────────────────────────
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // ── AdMob init — Firebase'den sonra, runApp'tan önce (F2-03) ────────────
  // fire-and-forget: hata olsa da uygulamayı bloklamasın
  unawaited(MobileAds.instance.initialize());

  // ── DI ──────────────────────────────────────────────────────────────────
  await configureDependencies();

  // ── Dataset seeding ─────────────────────────────────────────────────────
  await getIt<DatasetService>().seedWordsIfNeeded();

  // ── FCM async singleton hazır olana kadar bekle ──────────────────────────
  await getIt.allReady();

  // ── Deep link: FCM tap → route ──────────────────────────────────────────
  getIt<FCMService>().onNavigate.listen((route) {
    NavigationService.instance.navigateToPage(path: route);
  });

  // ── App ─────────────────────────────────────────────────────────────────
  runApp(const PratikApp());
}
