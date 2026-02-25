// lib/main_production.dart
//
// Production entry point.
// FlutterError.onError → Crashlytics (uncaught Flutter errors).
// PlatformDispatcher → Crashlytics (async errors).
// BLoC observer YOK (production'da gereksiz log).
// DatasetService.seedIfEmpty() çağrılır.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/init/navigation/navigation_service.dart';
import 'core/services/dataset_service.dart';
import 'firebase/messaging/fcm_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientation lock ────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase ────────────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Crashlytics: Flutter hatalarını yakala ──────────────────────────────
  if (!kDebugMode) {
    // Sync Flutter framework errors
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Async / PlatformDispatcher errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // ── DI ──────────────────────────────────────────────────────────────────
  await configureDependencies();

  // ── Dataset seeding ─────────────────────────────────────────────────────
  await getIt<DatasetService>().seedWordsIfNeeded();

  // ── FCM ─────────────────────────────────────────────────────────────────
  await getIt<FCMService>().initialize();

  // ── Deep link: FCM tap → route ──────────────────────────────────────────
  getIt<FCMService>().onNavigate.listen((route) {
    NavigationService.instance.navigateToPage(path: route);
  });

  // ── App ─────────────────────────────────────────────────────────────────
  runApp(const PratikApp());
}
