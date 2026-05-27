import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _userIdKey = 'last_user_id';
  static const _displayNameKey = 'last_display_name';
  static const _biometricUserIdKey = 'biometric_user_id';
  static const _biometricUsernameKey = 'biometric_username';

  Future<void> saveSession({required int userId, required String displayName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_displayNameKey, displayName);
  }

  Future<int?> lastUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_userIdKey);
    return id != null && id > 0 ? id : null;
  }

  Future<String?> lastDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayNameKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_displayNameKey);
  }

  Future<void> saveBiometricEnrollment({
    required int userId,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_biometricUserIdKey, userId);
    await prefs.setString(_biometricUsernameKey, username);
  }

  Future<({int userId, String username})?> biometricEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_biometricUserIdKey);
    final username = prefs.getString(_biometricUsernameKey);
    if (userId == null || userId <= 0 || username == null || username.isEmpty) {
      return null;
    }
    return (userId: userId, username: username);
  }

  Future<void> clearBiometricEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricUserIdKey);
    await prefs.remove(_biometricUsernameKey);
  }
}
