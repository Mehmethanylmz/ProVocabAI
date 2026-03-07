// lib/core/services/dataset_service.dart
//
// FAZ 15 — F15-05: DatasetService → WordSyncService dönüşümü
//
// Artık kelimeler Firestore'dan indirilir (words.json asset'i kaldırıldı).
// Bu sınıf, geriye dönük uyumluluk için WordSyncService'e delegate eder.
// Doğrudan SplashBloc bu sınıfı kullanmaya devam eder.
//
// Eski davranış: rootBundle.loadString('assets/data/words.json') → Drift seed
// Yeni davranış: WordSyncService → Firestore → Drift sync

import 'package:shared_preferences/shared_preferences.dart';

import '../../database/daos/word_dao.dart';
import 'word_sync_service.dart';

class DatasetService {
  final WordDao _wordDao;
  final SharedPreferences? _prefsOverride;

  // WordSyncService oluşturmak için gerekli. DI'dan inject edilir.
  final WordSyncService? _wordSyncService;

  const DatasetService({
    required WordDao wordDao,
    SharedPreferences? prefsOverride,
    WordSyncService? wordSyncService,
  })  : _wordDao = wordDao,
        _prefsOverride = prefsOverride,
        _wordSyncService = wordSyncService;

  /// Gerekiyorsa kelimeleri Firestore'dan indir — idempotent.
  ///
  /// [sourceLang]  : Kaynak dil (ör. 'tr')
  /// [targetLang]  : Hedef dil (ör. 'en')
  /// [onProgress]  : (synced, total) — gerçek zamanlı UI güncellemesi
  ///
  /// Dönüş: indirilen kelime sayısı (zaten senkronize ise 0).
  Future<int> seedWordsIfNeeded({
    String sourceLang = 'tr',
    String targetLang = 'en',
    void Function(int synced, int total)? onProgress,
  }) async {
    final syncService = await _getOrCreateSyncService();
    if (await syncService.isSynced(sourceLang, targetLang)) return 0;
    return syncService.syncWords(
      sourceLang: sourceLang,
      targetLang: targetLang,
      onProgress: onProgress,
    );
  }

  /// Senkronizasyon durumu.
  ///
  /// F15-04 (schema v2): SharedPreferences flag'e ek olarak word count kontrolü yapar.
  /// Schema migration sonrası tablolar drop edilirse flag hâlâ set'te kalabilir;
  /// word count 0 ise flag sıfırlanır ve false döner → yeniden indirme tetiklenir.
  Future<bool> isSeeded({
    String sourceLang = 'tr',
    String targetLang = 'en',
  }) async {
    final syncService = await _getOrCreateSyncService();
    if (!await syncService.isSynced(sourceLang, targetLang)) return false;
    // Post-migration guard: if tables were dropped, words are gone
    final count = await _wordDao.getWordCount();
    if (count == 0) {
      await syncService.resetSync(sourceLang, targetLang);
      return false;
    }
    return true;
  }

  /// Flag'i sıfırla — yeniden indirme için (dev/test only).
  Future<void> resetSeedFlag({
    String sourceLang = 'tr',
    String targetLang = 'en',
  }) async {
    final syncService = await _getOrCreateSyncService();
    await syncService.resetSync(sourceLang, targetLang);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<WordSyncService> _getOrCreateSyncService() async {
    if (_wordSyncService != null) return _wordSyncService;
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    return WordSyncService(wordDao: _wordDao, prefs: prefs);
  }
}
