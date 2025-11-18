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

  final Map<String, List<Map<String, dynamic>>> _weeklyActivityCache = {};
  final Map<String, Map<String, dynamic>> _monthlyProgressCache = {};

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
      _weeklyActivityCache[monthYear] = await _statsRepo
          .getWeeklyActivityStatsForMonth(monthYear);
      _monthlyProgressCache[monthYear] = await _statsRepo.getProgressForMonth(
        monthYear,
      );
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
    String weekOfYear,
    String year,
  ) async {
    return await _statsRepo.getDailyActivityStatsForWeek(weekOfYear, year);
  }
}
