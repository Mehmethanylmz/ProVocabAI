// test/firebase/sync/conflict_resolver_test.dart
//
// T-17 Acceptance Criteria:
//   AC: remote daha yeni → remoteWon, local stability güncellendi
//   AC: local daha yeni  → localWon, syncQueue'ya eklendi
//   AC: eşit updatedAt   → noConflict, remote kazanır (tie-break)
//   AC: resolveAll → karışık senaryo

import 'package:drift/drift.dart' show driftRuntimeOptions, Value;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pratikapp/database/app_database.dart';
import 'package:pratikapp/firebase/sync/conflict_resolver.dart';
import 'package:pratikapp/firebase/sync/sync_manager.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

// Her test kendi DB + manager + resolver alır → setUp yerine helper kullan
// Böylece Drift lazy open + PRAGMA FK sorunlarından kaçınılır.

AppDatabase _newDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase.forTesting(NativeDatabase.memory());
}

SyncManager _makeManager(AppDatabase db) => SyncManager(
      db: db,
      firestore: FakeFirebaseFirestore(),
      auth:
          MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'uid-test')),
    );

/// FK guard: words tablosuna önce ekle.
Future<void> _seedWord(AppDatabase db, int wordId) async {
  await db.wordDao.insertWordRaw(WordsCompanion(
    id: Value(wordId),
    contentJson: const Value('{"en":{"word":"test","meaning":"test"}}'),
    categoriesJson: const Value('["general"]'),
    sentencesJson: const Value('{}'),
    difficultyRank: const Value(1),
  ));
}

Future<ProgressData> _insertProgress(
  AppDatabase db, {
  required int wordId,
  required String targetLang,
  required int updatedAt,
  double stability = 1.0,
}) async {
  // FK: words tablosuna önce ekle (PRAGMA foreign_keys=ON)
  await _seedWord(db, wordId);
  await db.progressDao.upsertProgress(ProgressCompanion(
    wordId: Value(wordId),
    targetLang: Value(targetLang),
    stability: Value(stability),
    difficulty: const Value(5.0),
    repetitions: const Value(0),
    lapses: const Value(0),
    cardState: const Value('new'),
    nextReviewMs: Value(DateTime.now().millisecondsSinceEpoch),
    lastReviewMs: const Value(0),
    updatedAt: Value(updatedAt),
    isLeech: const Value(false),
    isSuspended: const Value(false),
  ));
  return (await db.progressDao.getCardProgress(
    wordId: wordId,
    targetLang: targetLang,
  ))!;
}

Map<String, dynamic> _remoteMap({
  required int wordId,
  required String targetLang,
  required int updatedAt,
  double stability = 1.0,
}) =>
    {
      'wordId': wordId,
      'targetLang': targetLang,
      'stability': stability,
      'difficulty': 5.0,
      'repetitions': 0,
      'lapses': 0,
      'cardState': 'new',
      'nextReviewMs': DateTime.now().millisecondsSinceEpoch,
      'lastReviewMs': 0,
      'updatedAt': updatedAt,
      'isLeech': false,
      'isSuspended': false,
    };

void main() {
  // ── resolve() ─────────────────────────────────────────────────────────────

  group('ConflictResolver.resolve()', () {
    test('AC: remote daha yeni → ConflictResult.remoteWon', () async {
      final db = _newDb();
      final manager = _makeManager(db);
      final resolver = ConflictResolver(db: db, syncManager: manager);

      final local = await _insertProgress(db,
          wordId: 1, targetLang: 'en', updatedAt: 1000);
      final remote = _remoteMap(
          wordId: 1, targetLang: 'en', updatedAt: 2000, stability: 3.5);

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result, ConflictResult.remoteWon);

      manager.dispose();
      await db.close();
    });

    test('AC: remote daha yeni → local stability güncellendi', () async {
      final db = _newDb();
      final manager = _makeManager(db);
      final resolver = ConflictResolver(db: db, syncManager: manager);

      final local = await _insertProgress(db,
          wordId: 2, targetLang: 'en', updatedAt: 1000, stability: 1.0);
      final remote = _remoteMap(
          wordId: 2, targetLang: 'en', updatedAt: 2000, stability: 5.0);

      await resolver.resolve(local: local, remote: remote);

      final updated =
          await db.progressDao.getCardProgress(wordId: 2, targetLang: 'en');
      expect(updated?.stability, closeTo(5.0, 0.001));

      manager.dispose();
      await db.close();
    });

    test('AC: local daha yeni → ConflictResult.localWon', () async {
      final db = _newDb();
      final manager = _makeManager(db);
      final resolver = ConflictResolver(db: db, syncManager: manager);

      final local = await _insertProgress(db,
          wordId: 3, targetLang: 'en', updatedAt: 5000);
      final remote = _remoteMap(wordId: 3, targetLang: 'en', updatedAt: 1000);

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result, ConflictResult.localWon);

      manager.dispose();
      await db.close();
    });

    test('AC: local daha yeni → syncQueue\'ya eklendi', () async {
      final db = _newDb();
      final manager = _makeManager(db);
      final resolver = ConflictResolver(db: db, syncManager: manager);

      final local = await _insertProgress(db,
          wordId: 4, targetLang: 'en', updatedAt: 9000);
      final remote = _remoteMap(wordId: 4, targetLang: 'en', updatedAt: 1000);

      await resolver.resolve(local: local, remote: remote);

      final pending = await db.syncQueueDao.getPending(entityType: 'progress');
      expect(pending.where((p) => p.entityId == '4:en').length, 1);

      manager.dispose();
      await db.close();
    });

    test('AC: updatedAt eşit → noConflict, remote kazanır (tie-break)',
        () async {
      final db = _newDb();
      final manager = _makeManager(db);
      final resolver = ConflictResolver(db: db, syncManager: manager);

      final ts = DateTime.now().millisecondsSinceEpoch;
      final local = await _insertProgress(db,
          wordId: 5, targetLang: 'en', updatedAt: ts, stability: 1.0);
      final remote = _remoteMap(
          wordId: 5, targetLang: 'en', updatedAt: ts, stability: 2.0);

      final result = await resolver.resolve(local: local, remote: remote);
      expect(result, ConflictResult.noConflict);

      // Remote uygulandı → stability=2.0
      final updated =
          await db.progressDao.getCardProgress(wordId: 5, targetLang: 'en');
      expect(updated?.stability, closeTo(2.0, 0.001));

      manager.dispose();
      await db.close();
    });
  });

  // ── resolveAll() ──────────────────────────────────────────────────────────

  group('ConflictResolver.resolveAll()', () {
    test('AC: karışık senaryolar → doğru outcome listesi', () async {
      final db = _newDb();
      final manager = _makeManager(db);
      final resolver = ConflictResolver(db: db, syncManager: manager);

      // word 10: remote daha yeni | word 11: local daha yeni
      final local10 = await _insertProgress(db,
          wordId: 10, targetLang: 'en', updatedAt: 1000);
      final local11 = await _insertProgress(db,
          wordId: 11, targetLang: 'en', updatedAt: 9000);

      final remotes = [
        _remoteMap(wordId: 10, targetLang: 'en', updatedAt: 5000),
        _remoteMap(wordId: 11, targetLang: 'en', updatedAt: 2000),
      ];

      final outcomes = await resolver.resolveAll(
        locals: [local10, local11],
        remotes: remotes,
      );

      expect(outcomes.length, 2);
      expect(outcomes.firstWhere((o) => o.entityId == '10:en').result,
          ConflictResult.remoteWon);
      expect(outcomes.firstWhere((o) => o.entityId == '11:en').result,
          ConflictResult.localWon);

      manager.dispose();
      await db.close();
    });

    test('AC: local\'de olmayan remote → remoteWon olarak uygulanır', () async {
      final db = _newDb();
      final manager = _makeManager(db);
      final resolver = ConflictResolver(db: db, syncManager: manager);

      // word 99 words tablosunda seed edilmeli (firestoreToProgress FK guard'ı
      // getCardProgress→null early-return yapar, yani word seed'e gerek yok)
      // firestoreToProgress: existing==null → return null (FK bypass edilir)
      final remotes = [
        _remoteMap(
            wordId: 99, targetLang: 'en', updatedAt: 5000, stability: 4.0),
      ];

      final outcomes = await resolver.resolveAll(locals: [], remotes: remotes);

      expect(outcomes.length, 1);
      expect(outcomes.first.result, ConflictResult.remoteWon);

      manager.dispose();
      await db.close();
    });
  });
}
