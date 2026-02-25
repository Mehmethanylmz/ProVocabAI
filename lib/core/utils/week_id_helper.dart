// lib/core/utils/week_id_helper.dart
//
// ISO week ID hesaplayıcı — Cloud Functions index.ts ile senkronize.
// Format: "2025-W04"

class WeekIdHelper {
  WeekIdHelper._();

  /// Şu anki ISO week ID'yi döndür.
  /// Cloud Function calculateWeeklyLeaderboard ile aynı algoritmayı kullanır.
  static String currentWeekId([DateTime? now]) {
    final date = now ?? DateTime.now().toUtc();
    final jan4 = DateTime.utc(date.year, 1, 4);
    final dayOfYear = date.difference(DateTime.utc(date.year)).inDays + 1;
    final weekNum = ((dayOfYear + jan4.weekday - 1) / 7).ceil();
    return '${date.year}-W${weekNum.toString().padLeft(2, '0')}';
  }
}
