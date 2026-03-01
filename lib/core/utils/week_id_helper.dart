// lib/core/utils/week_id_helper.dart
//
// ISO 8601 week ID hesaplayıcı — Cloud Functions index.ts ile senkronize.
// Format: "2026-W09"
//
// ISO kuralı: Yılın 1. haftası, Perşembeyi içeren haftadır.
// Algoritma: Dart'ın DateTime.weekday (1=Mon … 7=Sun) kullanılır.

class WeekIdHelper {
  WeekIdHelper._();

  /// Şu anki ISO 8601 week ID'yi döndür.
  /// Örnek: 27 Şubat 2026 → "2026-W09"
  ///
  /// [now] null ise UTC'deki gerçek saat kullanılır.
  static String currentWeekId([DateTime? now]) {
    return fromDate(now ?? DateTime.now().toUtc());
  }

  /// Verilen tarihin ISO week ID'sini döndür.
  static String fromDate(DateTime date) {
    // ISO 8601: Perşembe'yi içeren hafta = yılın 1. haftası.
    // Haftanın başı (Pazartesi) bulunur.
    final thursday = date
        .subtract(Duration(days: date.weekday - 1))
        .add(const Duration(days: 3));

    final firstDayOfYear = DateTime.utc(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(firstDayOfYear).inDays;
    final weekNum = (dayOfYear / 7).floor() + 1;

    return '${thursday.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

  /// Önceki hafta ID'si (leaderboard arşiv için).
  static String previousWeekId([DateTime? now]) {
    final date =
        (now ?? DateTime.now().toUtc()).subtract(const Duration(days: 7));
    return fromDate(date);
  }
}
