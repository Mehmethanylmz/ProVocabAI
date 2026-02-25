// lib/main_development.dart
//
// Development entry point.
// FlutterBlocObserver aktif — her BLoC event/state/error konsola loglanır.
// Crashlytics DEVRE DIŞI (development'ta crash gönderme).
// DatasetService.seedIfEmpty() çağrılır.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pratikapp/core/services/dataset_service.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
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

  // Development'ta Crashlytics KAPALI
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);

  // ── DI ──────────────────────────────────────────────────────────────────
  await configureDependencies();

  // ── BLoC observer (dev only) ────────────────────────────────────────────
  Bloc.observer = _DevBlocObserver();

  // ── Dataset seeding ─────────────────────────────────────────────────────
  // words tablosu boşsa assets/words.json'dan yükle (cold-start)
  await getIt<DatasetService>().seedWordsIfNeeded();

  // ── FCM ─────────────────────────────────────────────────────────────────
  await getIt<FCMService>().initialize();

  // ── App ─────────────────────────────────────────────────────────────────
  runApp(const PratikApp());
}

// ── Dev BLoC Observer ─────────────────────────────────────────────────────────

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
