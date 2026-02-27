// lib/main_development.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pratikapp/core/services/dataset_service.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'firebase_options.dart';

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

  // Development'ta Crashlytics KAPALI
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);

  // ── DI ──────────────────────────────────────────────────────────────────
  await configureDependencies();

  // ── BLoC observer (dev only) ────────────────────────────────────────────
  Bloc.observer = _DevBlocObserver();

  // ── Dataset seeding ─────────────────────────────────────────────────────
  await getIt<DatasetService>().seedWordsIfNeeded();

  // ── FCM ─────────────────────────────────────────────────────────────────
  await getIt.allReady();
  // ── App ─────────────────────────────────────────────────────────────────
  runApp(const PratikApp());
}

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
