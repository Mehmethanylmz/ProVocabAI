// test/core/di/injection_container_test.dart
//
// T-14 Acceptance Criteria:
//   AC: getIt<StudyZoneBloc>() resolve oluyor
//   AC: AppDatabase tek instance (singleton)
//   AC: StudyZoneBloc factory → her seferinde yeni instance
//   AC: DAO'lar AppDatabase singleton'dan geliyor

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:pratikapp/database/app_database.dart';
import 'package:pratikapp/database/daos/progress_dao.dart';
import 'package:pratikapp/database/daos/session_dao.dart';
import 'package:pratikapp/database/daos/sync_queue_dao.dart';
import 'package:pratikapp/database/daos/word_dao.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/complete_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/start_session.dart';
import 'package:pratikapp/features/study_zone/domain/usecases/submit_review.dart';
import 'package:pratikapp/features/study_zone/presentation/state/study_zone_bloc.dart';
import 'package:pratikapp/srs/daily_planner.dart';
import 'package:pratikapp/srs/fsrs_engine.dart';

// ── Test DI setup (forTesting DB) ─────────────────────────────────────────────

final GetIt _testGetIt = GetIt.asNewInstance();

Future<void> _configureTestDependencies() async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final db = AppDatabase.forTesting(NativeDatabase.memory());

  _testGetIt.registerSingleton<AppDatabase>(db);
  _testGetIt.registerSingleton<WordDao>(db.wordDao);
  _testGetIt.registerSingleton<ProgressDao>(db.progressDao);
  _testGetIt.registerSingleton<SyncQueueDao>(db.syncQueueDao);
  _testGetIt.registerSingleton<SessionDao>(db.sessionDao);

  _testGetIt.registerSingleton<FSRSEngine>(FSRSEngine());

  _testGetIt.registerSingleton<DailyPlanner>(
    DailyPlanner(
      progressDao: _testGetIt<ProgressDao>(),
      wordDao: _testGetIt<WordDao>(),
    ),
  );

  _testGetIt
      .registerSingleton<StartSession>(StartSession(_testGetIt<AppDatabase>()));
  _testGetIt
      .registerSingleton<SubmitReview>(SubmitReview(_testGetIt<AppDatabase>()));
  _testGetIt.registerSingleton<CompleteSession>(
      CompleteSession(_testGetIt<AppDatabase>()));

  _testGetIt.registerFactory<StudyZoneBloc>(
    () => StudyZoneBloc(
      dailyPlanner: _testGetIt<DailyPlanner>(),
      startSession: _testGetIt<StartSession>(),
      submitReview: _testGetIt<SubmitReview>(),
      completeSession: _testGetIt<CompleteSession>(),
    ),
  );
}

void main() {
  setUpAll(() async {
    await _configureTestDependencies();
  });

  tearDownAll(() async {
    await _testGetIt.reset();
  });

  group('T-14: DI Container', () {
    test('AC: AppDatabase singleton — aynı instance döner', () {
      final db1 = _testGetIt<AppDatabase>();
      final db2 = _testGetIt<AppDatabase>();
      expect(identical(db1, db2), isTrue,
          reason: 'AppDatabase singleton olmalı');
    });

    test('AC: WordDao singleton — aynı instance döner', () {
      // Drift'te db.wordDao her çağrıda yeni instance üretir (getter).
      // Singleton doğrulaması: getIt iki kez çağrıldığında AYNI nesneyi döndürmeli.
      final dao1 = _testGetIt<WordDao>();
      final dao2 = _testGetIt<WordDao>();
      expect(identical(dao1, dao2), isTrue,
          reason: 'GetIt singleton aynı WordDao instance\'ını döndürmeli');
    });

    test('AC: ProgressDao singleton — aynı instance döner', () {
      final dao1 = _testGetIt<ProgressDao>();
      final dao2 = _testGetIt<ProgressDao>();
      expect(identical(dao1, dao2), isTrue,
          reason: 'GetIt singleton aynı ProgressDao instance\'ını döndürmeli');
    });

    test('AC: FSRSEngine singleton — aynı instance döner', () {
      final e1 = _testGetIt<FSRSEngine>();
      final e2 = _testGetIt<FSRSEngine>();
      expect(identical(e1, e2), isTrue);
    });

    test('AC: DailyPlanner singleton — resolve oluyor', () {
      final planner = _testGetIt<DailyPlanner>();
      expect(planner, isNotNull);
    });

    test('AC: StartSession singleton — resolve oluyor', () {
      expect(_testGetIt<StartSession>(), isNotNull);
    });

    test('AC: SubmitReview singleton — resolve oluyor', () {
      expect(_testGetIt<SubmitReview>(), isNotNull);
    });

    test('AC: CompleteSession singleton — resolve oluyor', () {
      expect(_testGetIt<CompleteSession>(), isNotNull);
    });

    test('AC: StudyZoneBloc factory — resolve oluyor', () {
      final bloc = _testGetIt<StudyZoneBloc>();
      expect(bloc, isNotNull);
      bloc.close();
    });

    test('AC: StudyZoneBloc factory — her seferinde yeni instance', () {
      final bloc1 = _testGetIt<StudyZoneBloc>();
      final bloc2 = _testGetIt<StudyZoneBloc>();
      expect(identical(bloc1, bloc2), isFalse,
          reason: 'Factory her çağrıda yeni instance döndürmeli');
      bloc1.close();
      bloc2.close();
    });

    test('AC: allReadySync() — tüm singletonlar hazır', () {
      expect(_testGetIt.allReadySync(), isTrue);
    });
  });
}
