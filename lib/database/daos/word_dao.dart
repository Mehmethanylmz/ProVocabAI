import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/words_table.dart';
import '../tables/progress_table.dart';

part 'word_dao.g.dart';

/// WordDao — Kelime tablosu erişim katmanı.
///
/// T-07 (DatasetService) bu DAO'yu seeding için kullanır.
/// T-04 (DailyPlanner) getNewCards() ile yeni kart listesi alır.
/// T-10 (StudyZoneBloc) getWordById() + getRandomCandidates() ile quiz oluşturur.
@DriftAccessor(tables: [Words, Progress])
class WordDao extends DatabaseAccessor<AppDatabase> with _$WordDaoMixin {
  WordDao(super.db);

  // ── Seeding ──────────────────────────────────────────────────────────────

  /// words.json'dan parse edilen batch'i Drift'e yazar.
  /// ConflictAlgorithm.ignore: aynı id tekrar gelirse atla (idempotent).
  /// T-07 DatasetService 500'lük chunk'larla çağırır.
  Future<void> insertBatch(List<WordsCompanion> companions) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(words, companions);
    });
  }

  /// Tek kelime insert — test ve seed utility için.
  Future<void> insertWordRaw(WordsCompanion companion) =>
      into(words).insertOnConflictUpdate(companion);

  // ── Queries ──────────────────────────────────────────────────────────────

  /// Yeni kartlar: progress tablosunda kaydı OLMAYAN kelimeler.
  ///
  /// LEFT JOIN: progress kaydı yoksa yeni kart.
  /// ORDER BY difficulty_rank ASC: A1 önce, C2 sonra.
  /// T-04 DailyPlanner bu metodu çağırır.
  ///
  /// [targetLang]   : 'en', 'tr', 'de', vb.
  /// [categories]   : boş liste → tüm kategoriler.
  /// [limit]        : kaç kart dönsün (default 50).
  Future<List<Word>> getNewCards({
    required String targetLang,
    required List<String> categories,
    int limit = 50,
  }) async {
    // Drift customSelect: LEFT JOIN için type-safe builder yeterli değil.
    final categoryFilter = _buildCategoryFilter(categories);
    final categoryArgs = _buildCategoryArgs(categories);

    final query = '''
      SELECT w.*
      FROM words w
      LEFT JOIN progress p
        ON w.id = p.word_id
        AND p.target_lang = ?
      WHERE p.word_id IS NULL
        ${categoryFilter.isEmpty ? '' : 'AND ($categoryFilter)'}
      ORDER BY w.difficulty_rank ASC
      LIMIT ?
    ''';

    final args = <Object>[targetLang, ...categoryArgs, limit];

    final rows = await customSelect(
      query,
      variables: args.map((a) => Variable(a)).toList(),
      readsFrom: {words, progress},
    ).get();

    return rows.map((r) => words.map(r.data)).toList();
  }

  /// ID ile tek kelime getir.
  /// StudyZoneBloc._onNextCard() sıradaki kartı yüklerken kullanır.
  Future<Word?> getWordById(int id) =>
      (select(words)..where((w) => w.id.equals(id))).getSingleOrNull();

  /// Çoktan seçmeli sorular için yanlış şık adayları.
  /// StudyZoneBloc._buildDecoys() içinde kullanılır (T-10).
  /// ORDER BY RANDOM() — Drift'te orderBy ile yapılamaz, customSelect kullan.
  Future<List<Word>> getRandomCandidates({int limit = 50}) async {
    final rows = await customSelect(
      'SELECT * FROM words ORDER BY RANDOM() LIMIT ?',
      variables: [Variable(limit)],
      readsFrom: {words},
    ).get();
    return rows.map((r) => words.map(r.data)).toList();
  }

  /// İçerik içinde kelime arama (ayarlar ekranı / arama özelliği için).
  Future<List<Word>> searchWords(String query) {
    final pattern = '%$query%';
    return (select(words)
          ..where((w) =>
              w.contentJson.like(pattern) | w.partOfSpeech.like(pattern)))
        .get();
  }

  /// Toplam kelime sayısı — DatasetService ikinci açılışta kontrol için.
  Future<int> getWordCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM words',
      readsFrom: {words},
    ).getSingle();
    return result.data['cnt'] as int;
  }

  /// Kelime tablosu varlık kontrolü — T-01 schema test için.
  Future<bool> wordDao_tableExists() async {
    try {
      await customSelect('SELECT 1 FROM words LIMIT 1', readsFrom: {words})
          .get();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// categories listesinden SQL WHERE parçası üretir.
  /// Mevcut word_repository_impl.dart'taki LIKE pattern korundu (R-12 mitigation).
  /// Örn: categories = ['a1','b1'] → "categories LIKE ? OR categories LIKE ?"
  String _buildCategoryFilter(List<String> categories) {
    if (categories.isEmpty || categories.contains('all')) return '';
    return categories.map((_) => "w.categories_json LIKE ?").join(' OR ');
  }

  List<String> _buildCategoryArgs(List<String> categories) {
    if (categories.isEmpty || categories.contains('all')) return [];
    return categories.map((c) => '%"$c"%').toList();
  }
}
