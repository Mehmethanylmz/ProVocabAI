import 'package:flutter/foundation.dart';

import '../../../../core/base/base_view_model.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

class DashboardViewModel extends BaseViewModel {
  final IDashboardRepository _statsRepo;
  final ISettingsRepository _settingsRepo;

  DashboardViewModel(this._statsRepo, this._settingsRepo) {
    loadHomeData();
  }

  DashboardStatsEntity? _stats;
  DashboardStatsEntity? get stats => _stats;

  // Radar chart verileri
  Map<String, double> volumeStats = {
    'speaking': 0,
    'listening': 0,
    'quiz': 0,
    'vocabulary': 0
  };
  Map<String, double> accuracyStats = {
    'speaking': 0,
    'listening': 0,
    'quiz': 0,
    'vocabulary': 0
  };
  String coachMessage = "Analiz yapılıyor...";

  // Activity verileri
  List<Map<String, dynamic>> _monthlyActivity = [];
  List<Map<String, dynamic>> get monthlyActivity => _monthlyActivity;

  final Map<String, List<Map<String, dynamic>>> _weeklyActivityCache = {};
  final Map<String, Map<String, dynamic>> _monthlyProgressCache = {};

  Future<void> loadHomeData() async {
    changeLoading();

    String targetLang = 'en';
    final settingsResult = await _settingsRepo.getLanguageSettings();
    settingsResult.fold((l) => print("Ayarlar hatası"),
        (r) => targetLang = r['target'] ?? 'en');

    await fetchDashboardStats(targetLang);
    await fetchAllActivityStats();

    _calculateRealRadarStats();

    changeLoading();
  }

  Future<void> fetchDashboardStats(String targetLang) async {
    final result = await _statsRepo.getDashboardStats(targetLang);
    result.fold((l) => kDebugMode, (r) => _stats = r);
    notifyListeners();
  }

  Future<void> fetchAllActivityStats() async {
    final result = await _statsRepo.getMonthlyActivityStats();
    result.fold((l) => kDebugMode, (r) {
      _monthlyActivity = r;
    });

    _weeklyActivityCache.clear();
    _monthlyProgressCache.clear();

    for (var month in _monthlyActivity) {
      final monthYear = month['monthYear'] as String;

      final weeklyResult =
          await _statsRepo.getWeeklyActivityStatsForMonth(monthYear);
      weeklyResult.fold((l) {}, (r) => _weeklyActivityCache[monthYear] = r);

      final progressResult = await _statsRepo.getProgressForMonth(monthYear);
      progressResult.fold((l) {}, (r) => _monthlyProgressCache[monthYear] = r);
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> getWeeklyActivity(String monthYear) {
    return _weeklyActivityCache[monthYear] ?? [];
  }

  Map<String, dynamic> getMonthlyProgress(String monthYear) {
    return _monthlyProgressCache[monthYear] ?? {};
  }

  Future<List<Map<String, dynamic>>> getDailyStats(
      String weekOfYear, String year) async {
    final result =
        await _statsRepo.getDailyActivityStatsForWeek(weekOfYear, year);
    return result.getOrElse(() => []);
  }

  void _calculateRealRadarStats() {
    if (_stats == null) return;

    double generalSuccess = _stats!.weekSuccessRate;
    double vocabSuccess = (_stats!.masteredWords / 500 * 100).clamp(0.0, 100.0);
    double weeklyVolume = (_stats!.weekQuestions / 100 * 100).clamp(0.0, 100.0);

    accuracyStats = {
      'speaking': generalSuccess,
      'listening': generalSuccess,
      'quiz': generalSuccess,
      'vocabulary': vocabSuccess,
    };

    volumeStats = {
      'speaking': weeklyVolume * 0.8,
      'listening': weeklyVolume * 0.9,
      'quiz': weeklyVolume,
      'vocabulary': (_stats!.masteredWords / 1000 * 100).clamp(0.0, 100.0),
    };

    if (generalSuccess < 50) {
      coachMessage = "Daha fazla tekrar yapmalısın.";
    } else {
      coachMessage = "Harika gidiyorsun!";
    }
    notifyListeners();
  }

  String? generateShareProgressText() {
    if (_stats == null) return null;
    final tiers = _stats!.tierDistribution;
    return """
🚀 Kelime Uygulaması İlerlemem! 🚀

📊 **Genel İstatistikler**
- **Ustalaşılan Kelime:** ${_stats!.masteredWords}
- **Bu Hafta Çözülen:** ${_stats!.weekQuestions} Soru
- **Haftalık Başarı:** ${_stats!.weekSuccessRate.toStringAsFixed(0)}%

🧠 **Kelime Seviyelerim**
- **Uzman:** ${tiers['Expert'] ?? 0}
- **Çırak:** ${tiers['Apprentice'] ?? 0}
- **Acemi:** ${tiers['Novice'] ?? 0}
""";
  }
}
