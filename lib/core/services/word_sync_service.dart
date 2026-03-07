// lib/core/services/word_sync_service.dart
//
// FAZ 15 — F15-02: WordSyncService — Firestore → Drift dil filtreli indirme
//
// Sorumluluk:
//   - Firestore 'words' koleksiyonunu indirir → Drift words tablosuna yazar
//   - Sadece seçili dil çifti (sourceLang + targetLang) içeriğini indirir
//   - SharedPreferences flag: 'words_synced_{source}_{target}'
//   - Sayfalama: 500'lük Firestore limitiyle .startAfterDocument() pagination
//   - onProgress callback: gerçek zamanlı UI güncellemesi için
//
// F15-03/F15-04 NOT:
//   Drift şeması değişmedi (schemaVersion 1 korundu). Dil çifti bilgisi
//   uygulama genelinde ISettingsRepository'de tutulur (sourceLang/targetLang).
//   Words tablosu contentJson'da sadece seçili dil çiftinin içeriğini saklar.
//   Bu şekilde hem APK boyutu küçülür hem de build_runner gereksiz kalır.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/app_database.dart';
import '../../database/daos/word_dao.dart';

class WordSyncService {
  WordSyncService({
    required WordDao wordDao,
    required SharedPreferences prefs,
    FirebaseFirestore? firestore,
  })  : _wordDao = wordDao,
        _prefs = prefs,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final WordDao _wordDao;
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;

  static const _collection = 'words';
  static const _pageSize = 500;

  // ── SharedPreferences keys ────────────────────────────────────────────────

  static String _syncKey(String source, String target) =>
      'words_synced_${source}_$target';

  static String _countKey(String source, String target) =>
      'words_sync_count_${source}_$target';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Bu dil çifti için kelimeler zaten senkronize edildi mi?
  Future<bool> isSynced(String sourceLang, String targetLang) async =>
      _prefs.getBool(_syncKey(sourceLang, targetLang)) == true;

  /// Senkronize edilen kelime sayısı (0 = hiç senkronize edilmedi).
  int syncedCount(String sourceLang, String targetLang) =>
      _prefs.getInt(_countKey(sourceLang, targetLang)) ?? 0;

  /// Firestore'dan kelime verisi indir ve Drift'e yaz.
  ///
  /// [sourceLang]  : Kaynak dil (ör. 'tr') — kullanıcının anadili
  /// [targetLang]  : Hedef dil (ör. 'en') — öğrenilen dil
  /// [onProgress]  : (synced, total) — her sayfada çağrılır
  ///
  /// Dönüş: toplam indirilen kelime sayısı. Hata durumunda 0.
  Future<int> syncWords({
    required String sourceLang,
    required String targetLang,
    void Function(int synced, int total)? onProgress,
  }) async {
    try {
      // Toplam kelime sayısını al
      final countSnap = await _firestore
          .collection(_collection)
          .count()
          .get();
      final total = countSnap.count ?? 0;

      if (total == 0) return 0;

      onProgress?.call(0, total);

      int synced = 0;
      DocumentSnapshot? lastDoc;

      while (true) {
        // Sayfalama sorgusu
        var query = _firestore
            .collection(_collection)
            .orderBy('id')
            .limit(_pageSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snap = await query.get();
        if (snap.docs.isEmpty) break;

        lastDoc = snap.docs.last;

        // Drift companion'larına dönüştür
        final companions = <WordsCompanion>[];
        for (final doc in snap.docs) {
          final companion =
              _toCompanion(doc.data(), sourceLang, targetLang);
          if (companion != null) companions.add(companion);
        }

        if (companions.isNotEmpty) {
          await _wordDao.insertBatch(companions);
        }

        synced += snap.docs.length;
        onProgress?.call(synced, total);

        if (snap.docs.length < _pageSize) break;
      }

      // Sync flag kaydet
      await _prefs.setBool(_syncKey(sourceLang, targetLang), true);
      await _prefs.setInt(_countKey(sourceLang, targetLang), synced);

      return synced;
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[WordSyncService] syncWords error: $e');
        return true;
      }());
      return 0;
    }
  }

  /// Dil değişikliğinde ek dil içeriğini mevcut kelimelerle birleştirerek indir.
  ///
  /// Yeni dil çifti için senkronizasyonu sıfırlar ve tam yeniden indirir.
  /// [onProgress] ile UI'ı güncel tut.
  Future<int> syncLanguageContent({
    required String sourceLang,
    required String targetLang,
    void Function(int synced, int total)? onProgress,
  }) async {
    // Yeni çift için flag'i sıfırla → tam yeniden sync
    await _prefs.remove(_syncKey(sourceLang, targetLang));
    return syncWords(
      sourceLang: sourceLang,
      targetLang: targetLang,
      onProgress: onProgress,
    );
  }

  /// Sync flag'i sıfırla — yeniden indirme için (dev/test).
  Future<void> resetSync(String sourceLang, String targetLang) async {
    await _prefs.remove(_syncKey(sourceLang, targetLang));
    await _prefs.remove(_countKey(sourceLang, targetLang));
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Firestore dokümanını Drift WordsCompanion'a çevirir.
  /// Sadece [sourceLang] ve [targetLang] içeriği contentJson'a yazılır.
  WordsCompanion? _toCompanion(
    Map<String, dynamic> data,
    String sourceLang,
    String targetLang,
  ) {
    try {
      final id = (data['id'] as num?)?.toInt();
      if (id == null) return null;

      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      final partOfSpeech = (meta['part_of_speech'] as String?) ?? '';
      final transcription = meta['transcription'] as String?;
      final categories = meta['categories'];
      final categoriesJson = categories != null ? jsonEncode(categories) : '[]';
      final difficultyRank = (meta['difficulty_rank'] as num?)?.toInt() ?? 1;

      // Dil filtreli contentJson — sadece kaynak + hedef dil
      final contentRaw = data['content'] as Map<String, dynamic>? ?? {};
      final filteredContent = <String, dynamic>{};
      if (contentRaw.containsKey(sourceLang)) {
        filteredContent[sourceLang] = contentRaw[sourceLang];
      }
      if (contentRaw.containsKey(targetLang)) {
        filteredContent[targetLang] = contentRaw[targetLang];
      }
      // Hiç içerik yoksa tümünü al (beklenmedik dil çifti için fallback)
      final contentJson = filteredContent.isNotEmpty
          ? jsonEncode(filteredContent)
          : jsonEncode(contentRaw);

      final sentencesRaw = data['sentences'];
      final sentencesJson =
          sentencesRaw != null ? jsonEncode(sentencesRaw) : '{}';

      return WordsCompanion.insert(
        id: Value(id),
        partOfSpeech: Value(partOfSpeech),
        transcription: Value(transcription),
        categoriesJson: Value(categoriesJson),
        contentJson: Value(contentJson),
        sentencesJson: Value(sentencesJson),
        difficultyRank: Value(difficultyRank),
        sourceLang: Value(sourceLang), // F15-03: schema v2
        targetLang: Value(targetLang), // F15-03: schema v2
      );
    } catch (_) {
      return null;
    }
  }
}
