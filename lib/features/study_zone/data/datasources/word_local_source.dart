import '../../../../product/init/database/ProductDatabaseManager';
import '../models/word_model.dart';

abstract class WordLocalDataSource {
  Future<List<WordModel>> getDailyReviewWords(String targetLang, int limit);
  Future<void> updateWordProgress(
      int id, String lang, int level, int date, int streak);
}

class WordLocalDataSourceImpl implements WordLocalDataSource {
  final ProductDatabaseManager _dbManager;

  WordLocalDataSourceImpl(this._dbManager);

  @override
  Future<List<WordModel>> getDailyReviewWords(
      String targetLang, int limit) async {
    final db = await _dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM words 
      WHERE EXISTS (
        SELECT 1 FROM progress p 
        WHERE p.word_id = words.id 
        AND p.target_lang = ? 
        AND p.due_date <= ?
      ) 
      LIMIT ?
    ''', [targetLang, now, limit]);

    // Düzeltme: fromSqlMap yerine fromMap kullanıyoruz çünkü modelde öyle tanımlı.
    return maps.map((e) => WordModel.fromMap(e)).toList();
  }

  @override
  Future<void> updateWordProgress(
      int id, String lang, int level, int date, int streak) async {
    final db = await _dbManager.database;
    await db.rawInsert('''
      INSERT OR REPLACE INTO progress (word_id, target_lang, mastery_level, due_date, streak)
      VALUES (?, ?, ?, ?, ?)
    ''', [id, lang, level, date, streak]);
  }
}
