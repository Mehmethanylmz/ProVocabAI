import 'package:drift/drift.dart';

import 'words_table.dart';

/// Drift tablo tanımı: review_events
///
/// Her review işleminin immutable kaydı.
/// ÖNEMLİ: Bu tablo SADECE local'dir — Firestore'a YAZILMAZ (R-09 mitigation).
/// 90 günden eski kayıtlar ReviewEventDao.purgeOldEvents() ile temizlenir.
class ReviewEvents extends Table {
  /// UUID — SyncManager ile uyumlu unique ID.
  TextColumn get id => text()();

  /// FK → words.id
  IntColumn get wordId => integer().references(Words, #id)();

  /// Hangi oturumda yapıldı.
  TextColumn get sessionId => text()();

  /// Hedef dil.
  TextColumn get targetLang => text()();

  /// Review puanı: 'again' | 'hard' | 'good' | 'easy'
  TextColumn get rating => text()();

  /// Kullanıcının cevap süresi (ms).
  IntColumn get responseMs => integer()();

  /// Bu review'da kullanılan mod: 'mcq' | 'listening' | 'speaking'
  TextColumn get mode => text()();

  /// Cevap doğru muydu (rating != again → true).
  BoolColumn get wasCorrect => boolean()();

  /// Review anındaki FSRS stability değeri (log amaçlı).
  RealColumn get stabilityBefore => real()();

  /// Review sonrası FSRS stability değeri.
  RealColumn get stabilityAfter => real()();

  /// Review zamanı (Unix ms).
  IntColumn get reviewedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
