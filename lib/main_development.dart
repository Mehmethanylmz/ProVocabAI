// lib/main_development.dart
//
// Development entry point.
// - EasyLocalization aktif
// - BLoC observer açık (event/state log)
// - Crashlytics KAPALI
// - FCM background handler + deep link (F2-02)

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pratikapp/core/services/dataset_service.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/init/navigation/navigation_service.dart';
import 'firebase/messaging/fcm_service.dart';
import 'firebase_options.dart';

// ── FCM Background Handler — top-level, @pragma zorunlu ──────────────────────
// Bu fonksiyon FCMService.initialize() içinde de kaydediliyor.
// main'de tekrar kaydedilmesi Flutter'da harmless (son kayıt geçerli).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate'ta Firebase zaten init edilmiş olmalı.
  debugPrint('[FCM BG] messageId: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── EasyLocalization — runApp'tan ÖNCE zorunlu ──────────────────────────
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

  // ── FCM Background handler — Firebase.initializeApp'tan SONRA ───────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── Crashlytics: development'ta kapalı ──────────────────────────────────
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);

  // ── DI ──────────────────────────────────────────────────────────────────
  await configureDependencies();

  // ── BLoC observer (dev only) ────────────────────────────────────────────
  Bloc.observer = _DevBlocObserver();

  // ── Dataset seeding ─────────────────────────────────────────────────────
  await getIt<DatasetService>().seedWordsIfNeeded();

  // ── FCM async singleton'ın hazır olmasını bekle ──────────────────────────
  await getIt.allReady();

  // ── Deep link: FCM tap → NavigationService route ─────────────────────────
  getIt<FCMService>().onNavigate.listen((route) {
    NavigationService.instance.navigateToPage(path: route);
  });

  // ── App ─────────────────────────────────────────────────────────────────
  runApp(const PratikApp());
}

// ── Dev BLoC Observer ────────────────────────────────────────────────────────

class _DevBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint('[BLoC] ${bloc.runtimeType} EVENT → $event');
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    debugPrint(
      '[BLoC] ${bloc.runtimeType} '
      '${transition.currentState.runtimeType} → '
      '${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('[BLoC ERROR] ${bloc.runtimeType}: $error');
    super.onError(bloc, error, stackTrace);
  }
}
