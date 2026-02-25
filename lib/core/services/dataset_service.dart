// lib/core/services/dataset_service.dart
//
// Blueprint T-07: words.json → Drift seeding.
//
// Sorumluluk:
//   - SharedPreferences 'words_seeded_v1' flag kontrolü (early return)
//   - assets/data/words.json oku
//   - Isolate.run() ile JSON parse (UI thread block yok)
//   - 500'lük chunk'lar halinde WordDao.insertBatch()
//   - Flag set → ikinci açılışta 0 write
//
// Kullanım (product_init.dart veya SplashBloc._onAppStarted):
//   await DatasetService(wordDao: db.wordDao).seedWordsIfNeeded();
//
// pubspec.yaml bağımlılığı:
//   shared_preferences: ^2.2.0   (zaten ekli olmalı)
//   flutter:
//     assets:
//       - assets/data/words.json

import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pratikapp/database/app_database.dart' show WordsCompanion;
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/daos/word_dao.dart';

// ── Sabitler ─────────────────────────────────────────────────────────────────

class DatasetServiceConfig {
  /// SharedPreferences flag key. Versiyon değişince 'v2' gibi artır.
  static const String seededFlagKey = 'words_seeded_v1';

  /// Asset path — pubspec.yaml'da tanımlı olmalı.
  static const String assetPath = 'assets/data/words.json';

  /// Batch insert chunk boyutu.
  static const int chunkSize = 500;
}

// ── WordSeedEntry ─────────────────────────────────────────────────────────────

/// Isolate üzerinden parse edilen minimal kelime verisi.
/// Dart primitive — Isolate boundary'de güvenli taşınır.
class WordSeedEntry {
  final int id;
  final String partOfSpeech;
  final String categoriesJson;
  final String contentJson;
  final String sentencesJson;
  final int difficultyRank;

  const WordSeedEntry({
    required this.id,
    required this.partOfSpeech,
    required this.categoriesJson,
    required this.contentJson,
    required this.sentencesJson,
    required this.difficultyRank,
  });
}

// ── DatasetService ────────────────────────────────────────────────────────────

/// words.json varlığını Drift words tablosuna seed eder.
///
/// Blueprint T-07:
///   - İlk açılış: seeding → tablo dolu.
///   - İkinci açılış: flag var → early return, 0 write.
///   - 10k kelime < 4 saniye (Isolate + batch insert).
class DatasetService {
  final WordDao _wordDao;

  /// Test injection için — SharedPreferences mock edilebilir.
  final SharedPreferences? _prefsOverride;

  const DatasetService({
    required WordDao wordDao,
    SharedPreferences? prefsOverride,
  })  : _wordDao = wordDao,
        _prefsOverride = prefsOverride;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Gerekiyorsa seeding yap — idempotent.
  ///
  /// Dönüş: insert edilen kelime sayısı (ikinci açılışta 0).
  Future<int> seedWordsIfNeeded() async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();

    // Early return: daha önce seed yapıldı
    if (prefs.getBool(DatasetServiceConfig.seededFlagKey) == true) {
      return 0;
    }

    // JSON asset'i ana thread'de oku (rootBundle Isolate'de çalışmaz)
    final jsonString =
        await rootBundle.loadString(DatasetServiceConfig.assetPath);

    // JSON parse'ı Isolate'e taşı — UI thread block yok
    final entries = await Isolate.run<List<WordSeedEntry>>(
      () => _parseWordsJson(jsonString),
    );

    if (entries.isEmpty) return 0;

    // 500'lük chunk'lar halinde batch insert
    int inserted = 0;
    for (int i = 0; i < entries.length; i += DatasetServiceConfig.chunkSize) {
      final chunk = entries.sublist(
        i,
        (i + DatasetServiceConfig.chunkSize).clamp(0, entries.length),
      );
      final companions = chunk.map(_toCompanion).toList();
      await _wordDao.insertBatch(companions);
      inserted += chunk.length;
    }

    // Flag set — bir sonraki açılışta skip
    await prefs.setBool(DatasetServiceConfig.seededFlagKey, true);

    return inserted;
  }

  /// Flag'i sıfırla — force re-seed için (dev/test only).
  Future<void> resetSeedFlag() async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    await prefs.remove(DatasetServiceConfig.seededFlagKey);
  }

  /// Seeding tamamlandı mı?
  Future<bool> isSeeded() async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    return prefs.getBool(DatasetServiceConfig.seededFlagKey) == true;
  }

  // ── Private: JSON Parse (Isolate-safe) ───────────────────────────────────

  /// JSON string'i parse edip WordSeedEntry listesine çevirir.
  ///
  /// Tüm tipler Dart primitive — Isolate boundary'de güvenli.
  /// words.json formatı (WordModel.fromJson'dan türetildi):
  /// [
  ///   {
  ///     "id": 1,
  ///     "meta": { "part_of_speech": "noun", "categories": ["a1"], "difficulty_rank": 1 },
  ///     "content": { "en": { "word": "...", "meaning": "..." } },
  ///     "sentences": { "en": ["..."] }
  ///   }, ...
  /// ]
  static List<WordSeedEntry> _parseWordsJson(String jsonString) {
    final dynamic raw = json.decode(jsonString);

    // Root: List (standart) veya Map { "words": [...] }
    final List<dynamic> wordList;
    if (raw is List) {
      wordList = raw;
    } else if (raw is Map && raw['words'] is List) {
      wordList = raw['words'] as List;
    } else {
      return [];
    }

    final entries = <WordSeedEntry>[];
    for (final item in wordList) {
      if (item is! Map<String, dynamic>) continue;
      final entry = _parseEntry(item);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }

  static WordSeedEntry? _parseEntry(Map<String, dynamic> json) {
    try {
      final id = json['id'] as int?;
      if (id == null) return null;

      final meta = json['meta'] as Map<String, dynamic>? ?? {};
      final partOfSpeech = meta['part_of_speech'] as String? ?? 'unknown';
      final categoriesRaw = meta['categories'];
      final categoriesJson =
          categoriesRaw != null ? jsonEncode(categoriesRaw) : '[]';
      final difficultyRank = (meta['difficulty_rank'] as num?)?.toInt() ?? 1;

      final contentRaw = json['content'];
      final contentJson = contentRaw != null ? jsonEncode(contentRaw) : '{}';

      final sentencesRaw = json['sentences'];
      final sentencesJson =
          sentencesRaw != null ? jsonEncode(sentencesRaw) : '{}';

      return WordSeedEntry(
        id: id,
        partOfSpeech: partOfSpeech,
        categoriesJson: categoriesJson,
        contentJson: contentJson,
        sentencesJson: sentencesJson,
        difficultyRank: difficultyRank,
      );
    } catch (_) {
      return null; // malformed entry → skip
    }
  }

  // ── Private: Companion ────────────────────────────────────────────────────

  static WordsCompanion _toCompanion(WordSeedEntry e) => WordsCompanion.insert(
        id: Value(e.id),
        partOfSpeech: Value(e.partOfSpeech),
        categoriesJson: Value(e.categoriesJson),
        contentJson: Value(e.contentJson),
        sentencesJson: Value(e.sentencesJson),
        difficultyRank: Value(e.difficultyRank),
      );
}

// ── @visibleForTesting ────────────────────────────────────────────────────────

extension DatasetServiceTestable on DatasetService {
  /// Test ortamında _parseWordsJson'u expose et.
  static List<WordSeedEntry> parseWordsJsonPublic(String json) =>
      DatasetService._parseWordsJson(json);

  /// Test ortamında _toCompanion'u expose et.
  static WordsCompanion toCompanionPublic(WordSeedEntry e) =>
      DatasetService._toCompanion(e);
}
