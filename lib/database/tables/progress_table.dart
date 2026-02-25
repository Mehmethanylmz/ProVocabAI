import 'package:drift/drift.dart';

import 'words_table.dart';

/// Drift tablo tanımı: progress
///
/// Eski sqflite şeması (SİLİNDİ):
///   mastery_level INTEGER, due_date INTEGER, streak INTEGER, last_seen INTEGER
///
/// Yeni FSRS-4.5 şeması:
///   stability REAL, difficulty REAL, card_state TEXT, next_review_ms INTEGER,
///   last_review_ms INTEGER, lapses INTEGER, repetitions INTEGER,
///   is_leech BOOLEAN, is_suspended BOOLEAN, mode_history_json TEXT, updated_at INTEGER
///
/// Composite PK: (word_id, target_lang) — sqflite şemasıyla aynı.
class Progress extends Table {
  /// FK → words.id
  IntColumn get wordId => integer().references(Words, #id)();

  /// Hedef dil kodu: 'en', 'tr', 'es', 'de', 'fr', 'pt'
  TextColumn get targetLang => text()();

  // ── FSRS-4.5 Core Fields ──────────────────────────────────────────────────

  /// FSRS stability (gün cinsinden, continuous).
  /// Yeni kart cold-start: 0.5 (FSRS-4.5 w[2] default)
  RealColumn get stability => real().withDefault(const Constant(0.5))();

  /// FSRS difficulty (1.0–10.0 aralığı).
  /// Yeni kart cold-start: 5.0 (w[4] neutral)
  RealColumn get difficulty => real().withDefault(const Constant(5.0))();

  /// CardState: 'new' | 'learning' | 'review' | 'relearning'
  /// Default 'new' — progress tablosunda kayıt yoksa yeni kart anlamına gelir.
  TextColumn get cardState => text().withDefault(const Constant('new'))();

  /// Bir sonraki review zamanı (Unix ms).
  /// Yeni kart: DateTime.now().millisecondsSinceEpoch (hemen göster)
  IntColumn get nextReviewMs => integer().withDefault(const Constant(0))();

  /// Son review zamanı (Unix ms).
  IntColumn get lastReviewMs => integer().withDefault(const Constant(0))();

  /// Kaç kez "again" verildi (FSRS lapses).
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  /// Toplam başarılı review sayısı.
  IntColumn get repetitions => integer().withDefault(const Constant(0))();

  // ── Leech & Suspension ───────────────────────────────────────────────────

  /// lapses >= 4 → leech işaretlendi (LeechHandler tarafından set edilir).
  BoolColumn get isLeech => boolean().withDefault(const Constant(false))();

  /// lapses >= 8 → kullanıcı onayıyla suspend edildi.
  BoolColumn get isSuspended => boolean().withDefault(const Constant(false))();

  // ── Mode History ─────────────────────────────────────────────────────────

  /// ModeSelector için mod kullanım istatistiği.
  /// JSON encoded: '{"mcq":5,"listening":3,"speaking":2}'
  TextColumn get modeHistoryJson => text().withDefault(const Constant('{}'))();

  // ── Sync ─────────────────────────────────────────────────────────────────

  /// Son güncelleme zamanı (Unix ms) — ConflictResolver'da server-wins karşılaştırması için.
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {wordId, targetLang};
}
