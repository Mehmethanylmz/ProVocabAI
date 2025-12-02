import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  Future<void> clearUser();
  UserModel? getUser();
  bool hasToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences _prefs;

  AuthLocalDataSourceImpl(this._prefs);

  @override
  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(AppConstants.keyUserId, user.id);
    await _prefs.setString(AppConstants.keyUserEmail, user.email);
    await _prefs.setString(AppConstants.keyUserName, user.name);
    if (user.token != null) {
      await _prefs.setString(AppConstants.keyAuthToken, user.token!);
    }
  }

  @override
  Future<void> clearUser() async {
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keyUserEmail);
    await _prefs.remove(AppConstants.keyUserName);
    await _prefs.remove(AppConstants.keyAuthToken);
  }

  @override
  UserModel? getUser() {
    final id = _prefs.getString(AppConstants.keyUserId);
    if (id == null) return null;

    return UserModel(
      id: id,
      email: _prefs.getString(AppConstants.keyUserEmail) ?? '',
      name: _prefs.getString(AppConstants.keyUserName) ?? '',
      token: _prefs.getString(AppConstants.keyAuthToken),
    );
  }

  @override
  bool hasToken() {
    return _prefs.containsKey(AppConstants.keyAuthToken);
  }
}
