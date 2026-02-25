import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/words_table.dart';
import 'tables/progress_table.dart';
import 'tables/review_events_table.dart';
import 'tables/sessions_table.dart';
import 'tables/daily_plans_table.dart';
import 'tables/sync_queue_table.dart';

// DAO imports — T-02'de implement edilecek, şimdi forward declaration.
// Bu getter'lar T-02 tamamlandığında otomatik çalışır.
import 'daos/word_dao.dart';
import 'daos/progress_dao.dart';
import 'daos/review_event_dao.dart';
import 'daos/session_dao.dart';
import 'daos/daily_plan_dao.dart';
import 'daos/sync_queue_dao.dart';

part 'app_database.g.dart';

/// ProVocabAI ana Drift veritabanı.
///
/// Eski sistem: ProductDatabaseManager (sqflite, 4 tablo) — SİLİNDİ.
/// Yeni sistem: AppDatabase (Drift, 6 tablo, type-safe, codegen).
///
/// schemaVersion: 1 (greenfield — migration tarihi yok)
///
/// Kullanım:
///   final db = AppDatabase();           // normal
///   final db = AppDatabase(testDb());   // test isolate
@DriftDatabase(
  tables: [
    Words,
    Progress,
    ReviewEvents,
    Sessions,
    DailyPlans,
    SyncQueue,
  ],
  daos: [
    WordDao,
    ProgressDao,
    ReviewEventDao,
    SessionDao,
    DailyPlanDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Test için: in-memory veritabanı.
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        // schemaVersion 1 → migration yok (greenfield reset).
        // İleride versiyon artışında buraya eklenir.
        onUpgrade: (m, from, to) async {},
        beforeOpen: (details) async {
          // WAL modu: concurrent read + write performansı.
          await customStatement('PRAGMA journal_mode=WAL');
          // FK constraints aktif et.
          await customStatement('PRAGMA foreign_keys=ON');
        },
      );

  /// Performans için kritik indexler.
  /// getDueCards(), getNewCards(), getLeechCards() sorgularını hızlandırır.
  Future<void> _createIndexes() async {
    // Progress: due card query — blueprint E.4.1
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_progress_due
      ON progress (target_lang, next_review_ms, is_suspended, card_state)
    ''');

    // Progress: leech card query
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_progress_leech
      ON progress (target_lang, is_leech, is_suspended)
    ''');

    // Progress: sync queue pending
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_sync_queue_pending
      ON sync_queue (entity_type, deleted_at, retry_count)
    ''');

    // Review events: session lookup + purge
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_review_events_session
      ON review_events (session_id, reviewed_at)
    ''');

    // Review events: 90 gün temizlik için
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_review_events_date
      ON review_events (reviewed_at)
    ''');

    // Sessions: recent sessions
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_sessions_date
      ON sessions (target_lang, started_at)
    ''');

    // Words: difficulty rank ordering (getNewCards ORDER BY)
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_words_difficulty
      ON words (difficulty_rank)
    ''');
  }

  // ── DAO Getters (T-02 için hazır) ────────────────────────────────────────
  // @DriftDatabase daos: [] içinde tanımlandığı için Drift bu getter'ları
  // app_database.g.dart'ta otomatik üretir. Aşağıdakiler sadece
  // IDE completion ve explicit type hint için bırakılmıştır.

  WordDao get wordDao => WordDao(this);
  ProgressDao get progressDao => ProgressDao(this);
  ReviewEventDao get reviewEventDao => ReviewEventDao(this);
  SessionDao get sessionDao => SessionDao(this);
  DailyPlanDao get dailyPlanDao => DailyPlanDao(this);
  SyncQueueDao get syncQueueDao => SyncQueueDao(this);
}

/// Production connection: SQLite dosyası app documents klasöründe.
/// Eski veritabanı adı 'vocab_app_v2.db' — greenfield reset olduğu için
/// yeni ad kullanılır, eski dosya çakışması olmaz.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'provocalai_v1.db'));
    return NativeDatabase.createInBackground(file);
  });
}
