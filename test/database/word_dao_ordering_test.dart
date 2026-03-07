// test/database/word_dao_ordering_test.dart
//
// Word ordering audit (Phase 16 extra requirement):
//   - getNewCards filters by targetLang (F15-03 schema v2)
//   - getNewCards excludes words already in progress
//   - getNewCards respects difficulty_rank ordering (lower rank first)
//   - getNewCards uses RANDOM() secondary sort (F16 fix) — prevents
//     alphabetical clustering within the same difficulty level

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savgolearnvocabulary/database/app_database.dart';

AppDatabase _createTestDb() =>
    AppDatabase.forTesting(NativeDatabase.memory());

WordsCompanion _word(
  int id, {
  String targetLang = 'en',
  int rank = 1,
  String partOfSpeech = 'noun',
}) =>
    WordsCompanion.insert(
      id: Value(id),
      partOfSpeech: Value(partOfSpeech),
      categoriesJson: const Value('["a1"]'),
      contentJson: Value(
          '{"en":{"word":"word$id","meaning":"anlam$id"},"tr":{"word":"kelime$id","meaning":"word$id"}}'),
      sentencesJson: const Value(
          '{"beginner":{"en":"This is a sentence.","tr":"Bu bir cümle."}}'),
      difficultyRank: Value(rank),
      sourceLang: const Value('tr'),
      targetLang: Value(targetLang),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = _createTestDb());
  tearDown(() => db.close());

  group('WordDao.getNewCards — filtering', () {
    test('returns only words with matching targetLang', () async {
      // Insert 3 English words and 2 Turkish words
      for (var i = 1; i <= 3; i++) {
        await db.wordDao.insertWordRaw(_word(i, targetLang: 'en'));
      }
      for (var i = 4; i <= 5; i++) {
        await db.wordDao.insertWordRaw(_word(i, targetLang: 'tr'));
      }

      final results = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: [],
      );

      expect(results, hasLength(3));
      expect(results.every((w) => w.targetLang == 'en'), isTrue);
    });

    test('excludes words already in progress table', () async {
      for (var i = 1; i <= 5; i++) {
        await db.wordDao.insertWordRaw(_word(i));
      }

      // Mark word 1 and 2 as seen (in progress)
      for (final wordId in [1, 2]) {
        await db.into(db.progress).insert(ProgressCompanion.insert(
              wordId: wordId,
              targetLang: 'en',
            ));
      }

      final results = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: [],
      );

      expect(results, hasLength(3),
          reason: 'Words 1 and 2 are in progress, only 3,4,5 remain new');
      final ids = results.map((w) => w.id).toSet();
      expect(ids.contains(1), isFalse);
      expect(ids.contains(2), isFalse);
    });

    test('respects limit parameter', () async {
      for (var i = 1; i <= 10; i++) {
        await db.wordDao.insertWordRaw(_word(i));
      }

      final results = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: [],
        limit: 4,
      );

      expect(results, hasLength(4));
    });

    test('returns empty list when all words are in progress', () async {
      for (var i = 1; i <= 3; i++) {
        await db.wordDao.insertWordRaw(_word(i));
        await db.into(db.progress).insert(ProgressCompanion.insert(
              wordId: i,
              targetLang: 'en',
            ));
      }

      final results = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: [],
      );

      expect(results, isEmpty);
    });

    test('returns empty list when no words match targetLang', () async {
      // Only Turkish words
      for (var i = 1; i <= 3; i++) {
        await db.wordDao.insertWordRaw(_word(i, targetLang: 'tr'));
      }

      final results = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: [],
      );

      expect(results, isEmpty);
    });
  });

  group('WordDao.getNewCards — difficulty_rank ordering', () {
    test('lower difficulty_rank words are preferred over higher', () async {
      // 5 words: ranks 3,1,2,5,4
      final ranks = [3, 1, 2, 5, 4];
      for (var i = 0; i < 5; i++) {
        await db.wordDao
            .insertWordRaw(_word(i + 1, rank: ranks[i]));
      }

      // With limit=2, should get the 2 lowest rank words (rank 1 and 2)
      final results = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: [],
        limit: 2,
      );

      expect(results, hasLength(2));
      final returnedRanks = results.map((w) => w.difficultyRank).toList();
      // Both returned words should have rank 1 or 2 (not 3, 4, or 5)
      for (final rank in returnedRanks) {
        expect(rank, lessThanOrEqualTo(2),
            reason: 'With limit=2, only the 2 lowest ranked words should be returned');
      }
    });

    test('all returned words have rank <= highest selected rank', () async {
      // Insert 10 words with ranks 1-10
      for (var i = 1; i <= 10; i++) {
        await db.wordDao.insertWordRaw(_word(i, rank: i));
      }

      // Request 5 — should get ranks 1-5
      final results = await db.wordDao.getNewCards(
        targetLang: 'en',
        categories: [],
        limit: 5,
      );

      expect(results, hasLength(5));
      final maxReturnedRank =
          results.map((w) => w.difficultyRank).reduce((a, b) => a > b ? a : b);
      expect(maxReturnedRank, lessThanOrEqualTo(5),
          reason:
              'Should never return rank 6-10 when limit=5 and ranks 1-5 exist');
    });
  });

  group('WordDao.getNewCards — RANDOM() within same rank (F16 fix)', () {
    test('with 20 same-rank words, 5 calls produce at least 2 different orderings',
        () async {
      // Insert 20 words all with difficulty_rank=1
      for (var i = 1; i <= 20; i++) {
        await db.wordDao.insertWordRaw(_word(i, rank: 1));
      }

      // Call getNewCards 5 times with limit=5 (sampling without replacement not
      // applicable here — each call sees all 20 as "new" since no progress)
      final orderings = <List<int>>[];
      for (var call = 0; call < 5; call++) {
        final result = await db.wordDao.getNewCards(
          targetLang: 'en',
          categories: [],
          limit: 5,
        );
        orderings.add(result.map((w) => w.id).toList());
      }

      // Check that NOT all 5 calls returned the same ordering.
      // Probability of all same: (1/20)^5 * ... ≈ negligible.
      // We just verify at least 2 distinct orderings exist.
      final distinctOrderings =
          orderings.map((o) => o.join(',')).toSet();
      expect(distinctOrderings.length, greaterThan(1),
          reason:
              'With RANDOM() secondary sort, repeated queries on 20 same-rank '
              'words should produce different orderings');
    });
  });

  group('WordDao.getWordCount', () {
    test('returns 0 for empty table', () async {
      final count = await db.wordDao.getWordCount();
      expect(count, equals(0));
    });

    test('returns correct count after inserts', () async {
      for (var i = 1; i <= 7; i++) {
        await db.wordDao.insertWordRaw(_word(i));
      }
      final count = await db.wordDao.getWordCount();
      expect(count, equals(7));
    });
  });
}
