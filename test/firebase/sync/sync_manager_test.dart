// test/firebase/sync/sync_manager_test.dart
//
// T-16 Acceptance Criteria:
//   AC: offline review → syncQueue'da 1 kayıt
//   AC: syncAll() → pending yazılır, markSynced sonrası pending boş
//   AC: session entity → users/{uid}/sessions'a yazılır
//   AC: userId null → no-op
//   AC: cleanupRetryExceeded → 5 retry sonrası soft-delete
//
// Çalıştır: flutter test test/firebase/sync/sync_manager_test.dart

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pratikapp/database/app_database.dart';
import 'package:pratikapp/firebase/sync/sync_manager.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

AppDatabase _newDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase.forTesting(NativeDatabase.memory());
}

MockFirebaseAuth _authWithUser({String uid = 'test-uid'}) =>
    MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid));

MockFirebaseAuth _authNoUser() => MockFirebaseAuth(signedIn: false);

SyncManager _makeManager(AppDatabase db, MockFirebaseAuth auth) => SyncManager(
      db: db,
      firestore: FakeFirebaseFirestore(),
      auth: auth,
      // connectivity: null → listener kurulmaz, testlerde bağlantı değişimi yok
    );

void main() {
  // ── SyncQueue enqueue (offline simülasyonu) ───────────────────────────────

  group('SyncQueue enqueue', () {
    test('AC: offline review → syncQueue\'da 1 kayıt', () async {
      final db = _newDb();

      await db.syncQueueDao.enqueue(
        id: 'uuid-001',
        entityType: 'progress',
        entityId: '42:en',
        payloadJson: '{"wordId":42,"targetLang":"en"}',
      );

      final pending = await db.syncQueueDao.getPending(entityType: 'progress');
      expect(pending.length, 1);
      expect(pending.first.entityId, '42:en');
      expect(pending.first.retryCount, 0);
      expect(pending.first.deletedAt, isNull);

      await db.close();
    });

    test('AC: maxRetry aşan kayıt getPending\'e gelmez', () async {
      final db = _newDb();

      await db.syncQueueDao.enqueue(
        id: 'uuid-002',
        entityType: 'progress',
        entityId: '99:tr',
        payloadJson: '{}',
      );

      for (var i = 0; i < 5; i++) {
        await db.syncQueueDao.incrementRetry('uuid-002');
      }

      final pending = await db.syncQueueDao.getPending(entityType: 'progress');
      expect(pending.isEmpty, isTrue,
          reason: 'maxRetry=5 aşıldı, pending\'de gelmemeli');

      await db.close();
    });
  });

  // ── syncAll() no-op when unauthenticated ─────────────────────────────────

  group('syncAll no-op', () {
    test('AC: userId null → Firestore\'a erişilmez', () async {
      final db = _newDb();
      final fakeFirestore = FakeFirebaseFirestore();
      final manager = SyncManager(
        db: db,
        firestore: fakeFirestore,
        auth: _authNoUser(),
      );

      await db.syncQueueDao.enqueue(
        id: 'uuid-003',
        entityType: 'progress',
        entityId: '1:en',
        payloadJson: '{"wordId":1}',
      );

      await manager.syncAll();

      final docs =
          await fakeFirestore.collection('users/no-uid/progress').get();
      expect(docs.docs.isEmpty, isTrue);

      // Kayıt hâlâ pending'de
      final pending = await db.syncQueueDao.getPending(entityType: 'progress');
      expect(pending.length, 1);

      manager.dispose();
      await db.close();
    });
  });

  // ── syncAll() happy path ──────────────────────────────────────────────────

  group('syncAll happy path', () {
    test(
        'AC: online → pending kayıtlar Firestore\'a yazılır, markSynced sonrası pending boş',
        () async {
      final db = _newDb();
      final fakeFirestore = FakeFirebaseFirestore();
      final manager = SyncManager(
        db: db,
        firestore: fakeFirestore,
        auth: _authWithUser(uid: 'user-abc'),
      );

      await db.syncQueueDao.enqueue(
        id: 'sync-01',
        entityType: 'progress',
        entityId: '10:en',
        payloadJson: '{"wordId":10,"targetLang":"en","stability":2.5}',
      );
      await db.syncQueueDao.enqueue(
        id: 'sync-02',
        entityType: 'progress',
        entityId: '20:en',
        payloadJson: '{"wordId":20,"targetLang":"en","stability":1.0}',
      );

      await manager.syncAll();

      final docs =
          await fakeFirestore.collection('users/user-abc/progress').get();
      expect(docs.docs.length, 2);
      expect(
          docs.docs.map((d) => d.id).toSet(), containsAll(['10:en', '20:en']));

      final pending = await db.syncQueueDao.getPending(entityType: 'progress');
      expect(pending.isEmpty, isTrue,
          reason: 'markSynced sonrası pending boş olmalı');

      manager.dispose();
      await db.close();
    });

    test('AC: session entity → users/{uid}/sessions\'a yazılır', () async {
      final db = _newDb();
      final fakeFirestore = FakeFirebaseFirestore();
      final manager = SyncManager(
        db: db,
        firestore: fakeFirestore,
        auth: _authWithUser(uid: 'user-xyz'),
      );

      await db.syncQueueDao.enqueue(
        id: 'sess-01',
        entityType: 'session',
        entityId: 'session-uuid-001',
        payloadJson: '{"sessionId":"session-uuid-001","totalCards":10}',
      );

      await manager.syncPendingSessions('user-xyz');

      final doc = await fakeFirestore
          .collection('users/user-xyz/sessions')
          .doc('session-uuid-001')
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()?['totalCards'], 10);

      manager.dispose();
      await db.close();
    });
  });

  // ── cleanupRetryExceeded ──────────────────────────────────────────────────

  group('cleanupRetryExceeded', () {
    test('AC: 5 retry sonrası soft-delete yapılır', () async {
      final db = _newDb();

      await db.syncQueueDao.enqueue(
        id: 'fail-01',
        entityType: 'progress',
        entityId: '5:de',
        payloadJson: '{}',
      );

      for (var i = 0; i < 5; i++) {
        await db.syncQueueDao.incrementRetry('fail-01');
      }

      final cleaned = await db.syncQueueDao.cleanupRetryExceeded();
      expect(cleaned, 1);

      final failed = await db.syncQueueDao.getFailedCount();
      expect(failed, 1);

      await db.close();
    });
  });
}
