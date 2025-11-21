import 'package:flutter/material.dart';
import '../data/models/dashboard_stats.dart';
import '../data/models/word_model.dart';
import '../data/repositories/stats_repository.dart';
import '../data/repositories/word_repository.dart';
import '../data/repositories/settings_repository.dart';

class HomeViewModel with ChangeNotifier {
  final StatsRepository _statsRepo = StatsRepository();
  final WordRepository _wordRepo = WordRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DashboardStats? _stats;
  DashboardStats? get stats => _stats;

  List<Word> _difficultWords = [];
  List<Word> get difficultWords => _difficultWords;

  List<Map<String, dynamic>> _monthlyActivity = [];
  List<Map<String, dynamic>> get monthlyActivity => _monthlyActivity;

  Map<String, List<Map<String, dynamic>>> _weeklyActivityCache = {};
  Map<String, Map<String, dynamic>> _monthlyProgressCache = {};

  // --- GÜNCELLENEN RADAR VERİLERİ ---
  // İki ayrı veri seti tutuyoruz: Hacim (Miktar) ve Başarı (Kalite)
  Map<String, double> _volumeStats = {
    'speaking': 0,
    'listening': 0,
    'quiz': 0,
    'vocabulary': 0,
  };
  Map<String, double> get volumeStats => _volumeStats;

  Map<String, double> _accuracyStats = {
    'speaking': 0,
    'listening': 0,
    'quiz': 0,
    'vocabulary': 0,
  };
  Map<String, double> get accuracyStats => _accuracyStats;

  String _coachMessage = "coach_msg_general";
  String get coachMessage => _coachMessage;

  HomeViewModel() {
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    _isLoading = true;
    notifyListeners();

    final settings = await _settingsRepo.getLanguageSettings();
    final targetLang = settings['target']!;

    await fetchDashboardStats(targetLang);
    await fetchAllActivityStats();

    _calculateRealRadarStats(); // Gerçek verileri hesapla

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDashboardStats(String targetLang) async {
    _stats = await _statsRepo.getDashboardStats(targetLang);
    _difficultWords = await _wordRepo.getDifficultWords(targetLang);
    notifyListeners();
  }

  Future<void> fetchAllActivityStats() async {
    _monthlyActivity = await _statsRepo.getMonthlyActivityStats();
    _weeklyActivityCache.clear();
    _monthlyProgressCache.clear();
    for (var month in _monthlyActivity) {
      final monthYear = month['monthYear'] as String;
      _weeklyActivityCache[monthYear] =
          await _statsRepo.getWeeklyActivityStatsForMonth(monthYear);
      _monthlyProgressCache[monthYear] =
          await _statsRepo.getProgressForMonth(monthYear);
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
    return await _statsRepo.getDailyActivityStatsForWeek(weekOfYear, year);
  }

  // --- GERÇEK VERİ HESAPLAMA ---
  void _calculateRealRadarStats() {
    if (_stats == null) return;

    // 1. BAŞARI ORANI (ACCURACY) - NET 1
    // Şu an elimizde kategori bazlı ayrım olmadığı için genel başarıyı yansıtıyoruz.
    // İleride DB'den kategori bazlı gelirse burayı güncelleriz.
    double generalSuccess = _stats!.weekSuccessRate;

    // Ustalaşılan kelime oranını başarı kabul edelim (Hedef: 500 kelime varsayımı)
    double vocabSuccess = (_stats!.masteredWords / 500 * 100).clamp(0.0, 100.0);

    _accuracyStats = {
      'speaking': generalSuccess, // Şimdilik genel başarıyı kullanıyoruz
      'listening': generalSuccess,
      'quiz': generalSuccess,
      'vocabulary': vocabSuccess, // Kelime başarısı ayrı hesaplandı
    };

    // 2. ÇALIŞMA HACMİ (VOLUME) - NET 2
    // Haftalık hedef soru sayısı: 100 (Varsayım)
    double weeklyVolume = (_stats!.weekQuestions / 100 * 100).clamp(0.0, 100.0);
    // Toplam kelime hacmi (Hedef: 1000 kelimeye ne kadar yaklaştık)
    double vocabVolume = (_stats!.masteredWords / 1000 * 100).clamp(0.0, 100.0);

    _volumeStats = {
      'speaking':
          weeklyVolume * 0.8, // Konuşma genelde daha az yapılır, scale ettik
      'listening': weeklyVolume * 0.9,
      'quiz': weeklyVolume,
      'vocabulary': vocabVolume,
    };

    // Koç Mesajı Mantığı
    if (generalSuccess < 50) {
      _coachMessage = "Başarı oranın düşük, biraz daha tekrar yapmalısın!";
    } else if (weeklyVolume < 30) {
      _coachMessage = "Başarın güzel ama daha fazla pratik yapmalısın.";
    } else {
      _coachMessage = "Harika gidiyorsun! Temponu koru.";
    }
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
