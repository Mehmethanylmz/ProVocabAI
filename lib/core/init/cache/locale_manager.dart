import 'package:shared_preferences/shared_preferences.dart';

class LocaleManager {
  static final LocaleManager _instance = LocaleManager._init();
  SharedPreferences? _preferences;

  static LocaleManager get instance => _instance;

  LocaleManager._init() {
    SharedPreferences.getInstance().then((value) {
      _preferences = value;
    });
  }

  static Future<void> prefrencesInit() async {
    instance._preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> setStringValue(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  Future<void> setBoolValue(String key, bool value) async {
    await _preferences?.setBool(key, value);
  }

  Future<void> setIntValue(String key, int value) async {
    await _preferences?.setInt(key, value);
  }

  String getStringValue(String key) => _preferences?.getString(key) ?? '';
  bool getBoolValue(String key) => _preferences?.getBool(key) ?? false;
  int getIntValue(String key) => _preferences?.getInt(key) ?? 0;
}
