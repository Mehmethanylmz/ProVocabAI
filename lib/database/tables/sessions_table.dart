import 'package:drift/drift.dart';

/// Drift tablo tanımı: sessions
///
/// Her çalışma oturumunun özet kaydı.
/// SyncManager tarafından Firestore'a senkronize edilir
/// (users/{uid}/sessions/{sessionId}).
class Sessions extends Table {
  /// UUID — Firestore session doküman ID'si ile aynı.
  TextColumn get id => text()();

  /// Hedef dil.
  TextColumn get targetLang => text()();

  /// Birincil mod (en çok kullanılan): 'mcq' | 'listening' | 'speaking'
  TextColumn get mode => text().withDefault(const Constant('mcq'))();

  /// Oturum başlangıç zamanı (Unix ms).
  IntColumn get startedAt => integer()();

  /// Oturum bitiş zamanı (Unix ms). null → aktif oturum.
  IntColumn get endedAt => integer().nullable()();

  /// Toplam gösterilen kart sayısı.
  IntColumn get totalCards => integer().withDefault(const Constant(0))();

  /// Doğru cevaplanan kart sayısı (rating != again).
  IntColumn get correctCards => integer().withDefault(const Constant(0))();

  /// Bu oturumda kazanılan XP.
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();

  /// Seçilen kategoriler — JSON encoded: '["oxford-american/a1","a2"]'
  TextColumn get categoriesJson => text().withDefault(const Constant('[]'))();

  /// Firestore'a sync edildi mi?
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
