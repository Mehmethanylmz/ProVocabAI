import '../../../../core/base/base_view_model.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';
import '../../domain/entities/test_result_entity.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/i_test_repository.dart';
import '../../domain/repositories/i_word_repository.dart';

class MenuViewModel extends BaseViewModel {
  final IWordRepository _wordRepo;
  final ITestRepository _testRepo;
  final ISettingsRepository _settingsRepo;

  MenuViewModel(this._wordRepo, this._testRepo, this._settingsRepo) {
    loadMenuData();
  }

  // State
  List<TestResultEntity> _testHistory = [];
  List<TestResultEntity> get testHistory => _testHistory;

  int _dailyReviewCount = 0;
  int get dailyReviewCount => _dailyReviewCount;

  // Günlük hedef — batchSize'dan bağımsız
  int _dailyTarget = 20;
  int get dailyTarget => _dailyTarget;

  bool get isDailyGoalCompleted => _dailyReviewCount >= _dailyTarget;

  int _filteredWordCount = 0;
  int get filteredWordCount => _filteredWordCount;
  bool get canStartTest => _filteredWordCount > 0;

  List<WordEntity> _difficultWords = [];
  List<WordEntity> get difficultWords => _difficultWords;

  List<String> _allCategories = [];
  List<String> get allCategories => _allCategories;

  // Filtreler
  List<String> _selectedCategories = ['all'];
  List<String> get selectedCategories => _selectedCategories;

  Future<void> loadMenuData() async {
    changeLoading();

    // Ayarları Çek
    final settingsResult = await _settingsRepo.getLanguageSettings();
    String targetLang = 'en';
    settingsResult.fold((l) {}, (r) => targetLang = r['target']!);

    // Günlük hedefi ayrı key'den oku
    final dailyGoalResult = await _settingsRepo.getDailyGoal();
    dailyGoalResult.fold((l) {}, (r) => _dailyTarget = r);

    // Test soru sayısı (batchSize) artık sadece test için — menuye karışmıyor

    // 1. Geçmişi Sil ve Getir
    await _testRepo.deleteOldTestHistory();
    final historyResult = await _testRepo.getTestHistory();
    historyResult.fold((l) {}, (r) => _testHistory = r);

    // 2. Günlük Durum — dailyTarget kelimeden kaçı bugün yapıldı
    final dailyResult =
        await _wordRepo.getDailyReviewCount(_dailyTarget, targetLang);
    dailyResult.fold((l) {}, (r) => _dailyReviewCount = r);

    // 3. Difficult Words
    final difficultResult = await _wordRepo.getDifficultWords(targetLang);
    difficultResult.fold((l) {}, (r) => _difficultWords = r);

    // 4. Kategoriler
    final catResult = await _wordRepo.getAllUniqueCategories();
    catResult.fold((l) {}, (r) => _allCategories = r);

    // 5. Filtre Sayısını Güncelle
    await refreshFilteredCount();

    changeLoading();
  }

  Future<void> refreshFilteredCount() async {
    final settingsResult = await _settingsRepo.getLanguageSettings();
    String targetLang = 'en';
    settingsResult.fold((l) {}, (r) => targetLang = r['target']!);

    final countResult = await _wordRepo.getFilteredReviewCount(
        targetLang: targetLang, categories: _selectedCategories);
    countResult.fold((l) {}, (r) => _filteredWordCount = r);
    notifyListeners();
  }

  void toggleCategory(String category) {
    if (category == 'all') {
      _selectedCategories = ['all'];
    } else {
      if (_selectedCategories.contains('all')) {
        _selectedCategories.remove('all');
      }
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
      if (_selectedCategories.isEmpty) _selectedCategories = ['all'];
    }
    refreshFilteredCount();
  }
}
