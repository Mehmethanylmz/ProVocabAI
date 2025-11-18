import '../../core/database_helper.dart';
import '../models/test_result.dart';

class TestRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertTestResult(TestResult result) async {
    final db = await dbHelper.database;
    await db.insert('test_results', result.toMap());
  }

  Future<List<TestResult>> getTestHistory() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final threeDaysAgoEpoch = threeDaysAgo.millisecondsSinceEpoch;

    final maps = await db.query(
      'test_results',
      where: 'timestamp >= ?',
      whereArgs: [threeDaysAgoEpoch],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => TestResult.fromMap(map)).toList();
  }

  Future<void> deleteOldTestHistory() async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final threeDaysAgoEpoch = threeDaysAgo.millisecondsSinceEpoch;

    await db.delete(
      'test_results',
      where: 'timestamp < ?',
      whereArgs: [threeDaysAgoEpoch],
    );
  }
}
