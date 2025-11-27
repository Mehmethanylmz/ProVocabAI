import '../../../../core/base/base_view_model.dart';
import '../../../settings/domain/repositories/i_settings_repository.dart';

class OnboardingViewModel extends BaseViewModel {
  final ISettingsRepository _settingsRepo;

  OnboardingViewModel(this._settingsRepo) {
    _init();
  }

  // Sayfa Yönetimi
  int _currentPage = 0;
  int get currentPage => _currentPage;

  // Dil ve Seviye Seçimleri
  String _selectedSourceLang = 'en';
  String _selectedTargetLang = 'tr';
  String _selectedLevel = 'beginner';

  String get selectedSourceLang => _selectedSourceLang;
  String get selectedTargetLang => _selectedTargetLang;
  String get selectedLevel => _selectedLevel;

  // DİKKAT: Burada sadece KEY'leri (Kodları) tutuyoruz.
  // UI tarafında 'tr', 'en' kodlarına göre bayrak veya isim gösterilecek.
  final List<String> supportedLanguages = [
    'tr-TR',
    'en-US',
    'es-ES',
    'de-DE',
    'fr-FR',
    'pt-PT',
  ];

  // Seviyeler için de JSON anahtarlarını tutuyoruz.
  // UI tarafında "level_beginner".tr() diyerek çevirisini alacağız.
  final List<String> difficultyLevels = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  Future<void> _init() async {
    // Repository'den kayıtlı dil ayarlarını çekmeye çalışıyoruz (Eğer varsa)
    final result = await _settingsRepo.getLanguageSettings();

    result.fold((failure) {
      // Hata durumunda veya kayıt yoksa varsayılanlar kalır (en -> tr)
    }, (settings) {
      if (settings['source'] != null) _selectedSourceLang = settings['source']!;
      if (settings['target'] != null) _selectedTargetLang = settings['target']!;

      // Kayıtlı bir seviye varsa onu da çekebiliriz (İsteğe bağlı)
      // if (settings['level'] != null) _selectedLevel = settings['level']!;

      notifyListeners();
    });
  }

  void setSourceLang(String code) {
    if (_selectedSourceLang == code) return;
    _selectedSourceLang = code;

    // Eğer kaynak ve hedef aynı olursa, hedefi değiştir (Çakışma önleme)
    if (_selectedTargetLang == code) {
      _selectedTargetLang = (code == 'en') ? 'tr' : 'en';
    }
    notifyListeners();
  }

  void setTargetLang(String code) {
    if (code == _selectedSourceLang) return; // Kaynak ile aynı olamaz
    _selectedTargetLang = code;
    notifyListeners();
  }

  void setLevel(String level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < 2) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    changeLoading(); // Loading başlat

    await _settingsRepo.saveLanguageSettings(
        _selectedSourceLang, _selectedTargetLang);
    await _settingsRepo.saveProficiencyLevel(_selectedLevel);
    await _settingsRepo.completeOnboarding();

    changeLoading(); // Loading bitir
  }
}
