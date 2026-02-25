import 'package:drift/drift.dart';

/// Drift tablo tanımı: daily_plans
///
/// DailyPlanner.buildPlan() çıktısı burada persist edilir.
/// Her gün/dil için tek kayıt (upsert on conflict).
class DailyPlans extends Table {
  /// Plan tarihi: 'YYYY-MM-DD' formatında string.
  TextColumn get planDate => text()();

  /// Hedef dil.
  TextColumn get targetLang => text()();

  /// Planlanan kart ID listesi (sıralı) — JSON encoded: '[1,2,3,...]'
  /// PlanCard nesneleri yerine sadece word_id'ler tutulur (hafif).
  TextColumn get cardIdsJson => text().withDefault(const Constant('[]'))();

  /// Toplam kart sayısı (cardIds.length ile aynı — quick access).
  IntColumn get totalCards => integer().withDefault(const Constant(0))();

  /// Tamamlanan kart sayısı (session boyunca güncellenir).
  IntColumn get completedCards => integer().withDefault(const Constant(0))();

  /// Due kart sayısı (plan oluşturulurken snapshot).
  IntColumn get dueCount => integer().withDefault(const Constant(0))();

  /// Yeni kart sayısı (plan oluşturulurken snapshot).
  IntColumn get newCount => integer().withDefault(const Constant(0))();

  /// Leech kart sayısı (plan oluşturulurken snapshot).
  IntColumn get leechCount => integer().withDefault(const Constant(0))();

  /// Plan oluşturulma zamanı (Unix ms).
  IntColumn get createdAt => integer()();

  /// Tahmini çalışma süresi (dakika). DailyPlanner._estimateMinutes() ile hesaplanır.
  IntColumn get estimatedMinutes => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {planDate, targetLang};
}
