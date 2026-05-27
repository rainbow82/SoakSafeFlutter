import 'package:soaksafe/core/database/app_database.dart';
import 'package:soaksafe/core/models/models.dart';
import 'package:soaksafe/core/security/password_hasher.dart';

enum LoginResult { success, invalidCredentials, emptyFields }

enum RegisterResult { success, usernameTaken, emptyFields }

enum UpdateProfileResult {
  success,
  usernameTaken,
  emptyUsername,
  invalidPoolSize,
  userNotFound,
}

class UserRepository {
  UserRepository(this._db);

  final AppDatabase _db;

  Future<LoginResult> tryLogin(String username, String password) async {
    final u = username.trim();
    final p = password;
    if (u.isEmpty || p.isEmpty) return LoginResult.emptyFields;

    final user = await _db.userByUsername(u);
    if (user == null || !PasswordHasher.verify(user.password, p)) {
      return LoginResult.invalidCredentials;
    }

    if (!PasswordHasher.isModernStoredForm(user.password)) {
      await _db.updatePassword(user.id, PasswordHasher.hash(p));
    }
    return LoginResult.success;
  }

  Future<(RegisterResult, UserRecord?)> registerUser({
    required String fullName,
    required String username,
    required String password,
    required int poolSizeGallons,
    required bool poolSaltWater,
  }) async {
    final name = fullName.trim();
    final u = username.trim();
    if (name.isEmpty || u.isEmpty || password.isEmpty) {
      return (RegisterResult.emptyFields, null);
    }
    if (await _db.countUsername(u) > 0) {
      return (RegisterResult.usernameTaken, null);
    }
    final id = await _db.insertUser(
      UserRecord(
        id: 0,
        username: u,
        password: PasswordHasher.hash(password),
        fullName: name,
        poolSizeGallons: poolSizeGallons,
        poolSaltWater: poolSaltWater,
        poolAboveGround: false,
      ),
    );
    final created = await _db.userById(id);
    return (RegisterResult.success, created);
  }

  Future<UserRecord?> userByUsername(String username) =>
      _db.userByUsername(username);

  Future<UserRecord?> userById(int id) => _db.userById(id);

  Future<(UpdateProfileResult, UserRecord?)> updateProfile({
    required int userId,
    required String username,
    required int poolSizeGallons,
    required bool poolSaltWater,
    required bool poolAboveGround,
  }) async {
    final u = username.trim();
    if (u.isEmpty) return (UpdateProfileResult.emptyUsername, null);
    if (poolSizeGallons <= 0) return (UpdateProfileResult.invalidPoolSize, null);

    final row = await _db.userById(userId);
    if (row == null) return (UpdateProfileResult.userNotFound, null);

    if (row.username.toLowerCase() != u.toLowerCase() &&
        await _db.countUsername(u, excludeUserId: userId) > 0) {
      return (UpdateProfileResult.usernameTaken, null);
    }

    final updated = UserRecord(
      id: row.id,
      username: u,
      password: row.password,
      fullName: row.fullName,
      poolSizeGallons: poolSizeGallons,
      poolSaltWater: poolSaltWater,
      poolAboveGround: poolAboveGround,
    );
    await _db.updateUserProfile(updated);
    return (UpdateProfileResult.success, updated);
  }
}
