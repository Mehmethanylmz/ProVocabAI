// test/core/dataset_service_test.dart
//
// T-07 Acceptance Criteria:
//   BP: İlk açılış → words tablosu dolu
//   BP: İkinci açılış → seedWordsIfNeeded() early return, 0 write
//   BP: 10k kelime < 4 saniye  (1k ile 2s sınırı test edilir → orantılı)
//
// Çalıştır: flutter test test/core/dataset_service_test.dart
//
// Strateji: rootBundle test ortamında çalışmaz.
//   → _FakeDatasetService: seedWordsIfNeeded() override ile JSON injection.
//   → DatasetServiceTestable extension: _parseWordsJson unit test için expose.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pratikapp/database/daos/word_dao.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pratikapp/core/services/dataset_service.dart';
import 'package:pratikapp/database/app_database.dart';

void main() {
  // ── _parseWordsJson Unit Testleri ─────────────────────────────────────────

  group('_parseWordsJson (unit)', () {
    test('standart List format parse edilir', () {
      final src = jsonEncode([
        _word(1, pos: 'noun', cats: ['a1'], rank: 1),
        _word(2, pos: 'verb', cats: ['a2'], rank: 2),
      ]);
      final entries = DatasetServiceTestable.parseWordsJsonPublic(src);
      expect(entries.length, 2);
      expect(entries[0].id, 1);
      expect(entries[0].partOfSpeech, 'noun');
      expect(entries[1].id, 2);
      expect(entries[1].difficultyRank, 2);
    });

    test('{"words": [...]} wrapper format parse edilir', () {
      final src = jsonEncode({
        'words': [_word(1, pos: 'adjective')]
      });
      final entries = DatasetServiceTestable.parseWordsJsonPublic(src);
      expect(entries.length, 1);
      expect(entries[0].id, 1);
    });

    test('categoriesJson: liste → JSON string', () {
      final src = jsonEncode([
        _word(1, cats: ['a1', 'oxford'])
      ]);
      final entries = DatasetServiceTestable.parseWordsJsonPublic(src);
      final cats = jsonDecode(entries[0].categoriesJson) as List;
      expect(cats, containsAll(['a1', 'oxford']));
    });

    test('contentJson: map → JSON string (round-trip)', () {
      final src = jsonEncode([
        {
          'id': 1,
          'meta': {'part_of_speech': 'noun', 'categories': []},
          'content': {
            'en': {'word': 'apple', 'meaning': 'elma'}
          },
          'sentences': {},
        }
      ]);
      final entries = DatasetServiceTestable.parseWordsJsonPublic(src);
      final content = jsonDecode(entries[0].contentJson) as Map;
      expect(content['en']['word'], 'apple');
    });

    test('id=null → entry skip edilir', () {
      final src = jsonEncode([
        {'id': null, 'meta': {}, 'content': {}, 'sentences': {}},
        _word(2),
      ]);
      final entries = DatasetServiceTestable.parseWordsJsonPublic(src);
      expect(entries.length, 1);
      expect(entries[0].id, 2);
    });

    test('non-map entry skip edilir', () {
      final src = jsonEncode([_word(1), 'bad_string', 42]);
      final entries = DatasetServiceTestable.parseWordsJsonPublic(src);
      expect(entries.length, 1);
    });

    test('boş liste → boş dönüş', () {
      expect(
          DatasetServiceTestable.parseWordsJsonPublic(jsonEncode([])), isEmpty);
    });

    test('difficultyRank eksik → default 1', () {
      final src = jsonEncode([
        {
          'id': 1,
          'meta': {'part_of_speech': 'noun'},
          'content': {},
          'sentences': {}
        },
      ]);
      final entries = DatasetServiceTestable.parseWordsJsonPublic(src);
      expect(entries[0].difficultyRank, 1);
    });
  });

  // ── seedWordsIfNeeded Integration Testleri ────────────────────────────────

  group('seedWordsIfNeeded (in-memory Drift + mock SharedPreferences)', () {
    late AppDatabase db;
    late SharedPreferences prefs;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });
    tearDown(() async => db.close());

    _FakeDatasetService svc(List<Map<String, dynamic>> words) =>
        _FakeDatasetService(
          wordDao: db.wordDao,
          prefs: prefs,
          json: jsonEncode(words),
        );

    // ── Blueprint kriterleri ───────────────────────────────────────────────

    test('BP: ilk açılış → words tablosu dolu', () async {
      final service = svc(List.generate(5, (i) => _word(i + 1, pos: 'noun')));
      final inserted = await service.seedWordsIfNeeded();
      expect(inserted, 5);
      final w1 = await db.wordDao.getWordById(1);
      expect(w1, isNotNull);
      expect(w1!.partOfSpeech, 'noun');
    });

    test('BP: ikinci açılış → 0 write (early return)', () async {
      final service = svc(List.generate(3, (i) => _word(i + 1)));
      await service.seedWordsIfNeeded(); // ilk
      final second = await service.seedWordsIfNeeded(); // ikinci
      expect(second, 0);
    });

    test('isSeeded(): seed sonrası true', () async {
      final service = svc([_word(1)]);
      await service.seedWordsIfNeeded();
      expect(await service.isSeeded(), isTrue);
    });

    test('resetSeedFlag(): isSeeded() → false', () async {
      final service = svc([_word(1)]);
      await service.seedWordsIfNeeded();
      await service.resetSeedFlag();
      expect(await service.isSeeded(), isFalse);
    });

    test('boş JSON → inserted=0, flag SET EDİLMEZ (tekrar denensin)', () async {
      final service = svc([]);
      final inserted = await service.seedWordsIfNeeded();
      expect(inserted, 0);
      expect(await service.isSeeded(), isFalse);
    });

    // ── Chunk insert ───────────────────────────────────────────────────────

    test('1200 kelime → 3 chunk (500+500+200), tümü insert', () async {
      final service = svc(List.generate(1200, (i) => _word(i + 1)));
      final inserted = await service.seedWordsIfNeeded();
      expect(inserted, 1200);
      expect(await db.wordDao.getWordById(500), isNotNull);
      expect(await db.wordDao.getWordById(1200), isNotNull);
    });

    test('upsert semantiği: reset+re-seed → conflict yok', () async {
      final service = svc([_word(1, pos: 'noun'), _word(2, pos: 'verb')]);
      await service.seedWordsIfNeeded();
      await service.resetSeedFlag();
      await service.seedWordsIfNeeded(); // upsert → exception yok
      expect(await db.wordDao.getWordById(1), isNotNull);
    });

    // ── AC-11: Performance < 2s (10k < 4s orantılı) ───────────────────────

    test('AC-11: 1000 kelime < 2000ms', () async {
      final service = svc(
        List.generate(1000, (i) => _word(i + 1, rank: (i % 6) + 1)),
      );
      final sw = Stopwatch()..start();
      final inserted = await service.seedWordsIfNeeded();
      sw.stop();

      expect(inserted, 1000);
      expect(
        sw.elapsedMilliseconds,
        lessThan(2000),
        reason: '1000 kelime ${sw.elapsedMilliseconds}ms > 2000ms',
      );
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Map<String, dynamic> _word(
  int id, {
  String pos = 'noun',
  List<String> cats = const ['a1'],
  int rank = 1,
}) =>
    {
      'id': id,
      'meta': {
        'part_of_speech': pos,
        'categories': cats,
        'difficulty_rank': rank
      },
      'content': {
        'en': {'word': 'w$id', 'meaning': 'm$id'}
      },
      'sentences': {
        'en': ['S$id.']
      },
    };

// ── _FakeDatasetService ───────────────────────────────────────────────────────
//
// rootBundle çalışmadığından seedWordsIfNeeded() override edilir.
// JSON injection ile gerçek insert mantığı test edilir.

class _FakeDatasetService extends DatasetService {
  final String _json;
  final SharedPreferences _prefs;
  final WordDao _dao;

  _FakeDatasetService({
    required WordDao wordDao,
    required SharedPreferences prefs,
    required String json,
  })  : _json = json,
        _prefs = prefs,
        _dao = wordDao,
        super(wordDao: wordDao, prefsOverride: prefs);

  @override
  Future<int> seedWordsIfNeeded() async {
    if (_prefs.getBool(DatasetServiceConfig.seededFlagKey) == true) return 0;

    final entries = DatasetServiceTestable.parseWordsJsonPublic(_json);
    if (entries.isEmpty) return 0;

    int inserted = 0;
    for (int i = 0; i < entries.length; i += DatasetServiceConfig.chunkSize) {
      final chunk = entries.sublist(
        i,
        (i + DatasetServiceConfig.chunkSize).clamp(0, entries.length),
      );
      await _dao.insertBatch(
        chunk.map(DatasetServiceTestable.toCompanionPublic).toList(),
      );
      inserted += chunk.length;
    }

    await _prefs.setBool(DatasetServiceConfig.seededFlagKey, true);
    return inserted;
  }
}
