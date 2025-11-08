import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _batchSizeKey = 'batchSize';

  Future<void> saveBatchSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_batchSizeKey, size);
  }

  Future<int> getBatchSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_batchSizeKey) ?? 30;
  }
}
