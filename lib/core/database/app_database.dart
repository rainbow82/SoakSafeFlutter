import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:soaksafe/core/models/models.dart';

class AppDatabase {
  AppDatabase._(this._db);

  static AppDatabase? _instance;
  final Database _db;

  static Future<AppDatabase> open(String path) async {
    if (_instance != null) return _instance!;
    final db = await openDatabase(
      join(path, 'soaksafe.db'),
      version: 10,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            fullName TEXT NOT NULL,
            pool_size_gallons INTEGER NOT NULL DEFAULT 0,
            pool_salt_water INTEGER NOT NULL DEFAULT 0,
            pool_above_ground INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await database.execute('''
          CREATE TABLE maintenance_details (
            userId INTEGER PRIMARY KEY,
            dateMillis INTEGER NOT NULL,
            FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE maintenance_checklist (
            userId INTEGER PRIMARY KEY,
            vacuum INTEGER NOT NULL DEFAULT 0,
            clean_skimmer INTEGER NOT NULL DEFAULT 0,
            add_water INTEGER NOT NULL DEFAULT 0,
            brush_walls INTEGER NOT NULL DEFAULT 0,
            chlorine REAL NOT NULL DEFAULT 0,
            ph_up REAL NOT NULL DEFAULT 0,
            ph_down REAL NOT NULL DEFAULT 0,
            no_phos REAL NOT NULL DEFAULT 0,
            custom_lines_json TEXT,
            FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE maintenance_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            event_type TEXT NOT NULL,
            event_time_millis INTEGER NOT NULL,
            dateMillis INTEGER NOT NULL,
            vacuum INTEGER NOT NULL DEFAULT 0,
            clean_skimmer INTEGER NOT NULL DEFAULT 0,
            add_water INTEGER NOT NULL DEFAULT 0,
            brush_walls INTEGER NOT NULL DEFAULT 0,
            chlorine REAL NOT NULL DEFAULT 0,
            ph_up REAL NOT NULL DEFAULT 0,
            ph_down REAL NOT NULL DEFAULT 0,
            no_phos REAL NOT NULL DEFAULT 0,
            line_items_json TEXT,
            FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
        await database.execute(
          'CREATE INDEX idx_maintenance_events_userId ON maintenance_events(userId)',
        );
      },
    );
    _instance = AppDatabase._(db);
    return _instance!;
  }

  Future<UserRecord?> userByUsername(String username) async {
    final rows = await _db.query(
      'users',
      where: 'username = ? COLLATE NOCASE',
      whereArgs: [username.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first);
  }

  Future<UserRecord?> userById(int id) async {
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _userFromRow(rows.first);
  }

  Future<int> countUsername(String username, {int? excludeUserId}) async {
    if (excludeUserId == null) {
      final result = await _db.rawQuery(
        'SELECT COUNT(*) AS c FROM users WHERE username = ? COLLATE NOCASE',
        [username.trim()],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM users WHERE username = ? COLLATE NOCASE AND id != ?',
      [username.trim(), excludeUserId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> insertUser(UserRecord user) async {
    return _db.insert('users', {
      'username': user.username,
      'password': user.password,
      'fullName': user.fullName,
      'pool_size_gallons': user.poolSizeGallons,
      'pool_salt_water': user.poolSaltWater ? 1 : 0,
      'pool_above_ground': user.poolAboveGround ? 1 : 0,
    });
  }

  Future<void> updateUserProfile(UserRecord user) async {
    await _db.update(
      'users',
      {
        'username': user.username,
        'pool_size_gallons': user.poolSizeGallons,
        'pool_salt_water': user.poolSaltWater ? 1 : 0,
        'pool_above_ground': user.poolAboveGround ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> updatePassword(int userId, String passwordHash) async {
    await _db.update(
      'users',
      {'password': passwordHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<ChecklistRecord> getOrCreateChecklist(int userId) async {
    final rows = await _db.query(
      'maintenance_checklist',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      final row = ChecklistRecord(userId: userId);
      await upsertChecklist(row);
      return row;
    }
    return _checklistFromRow(rows.first);
  }

  Future<void> upsertChecklist(ChecklistRecord row) async {
    await _db.insert(
      'maintenance_checklist',
      {
        'userId': row.userId,
        'vacuum': row.vacuum ? 1 : 0,
        'clean_skimmer': row.cleanSkimmer ? 1 : 0,
        'add_water': row.addWater ? 1 : 0,
        'brush_walls': row.brushWalls ? 1 : 0,
        'chlorine': row.chlorine,
        'ph_up': row.phUp,
        'ph_down': row.phDown,
        'no_phos': row.noPhos,
        'custom_lines_json': row.customLinesJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertMaintenanceDate(int userId, int dateMillis) async {
    await _db.insert(
      'maintenance_details',
      {'userId': userId, 'dateMillis': dateMillis},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> maintenanceDateMillis(int userId) async {
    final rows = await _db.query(
      'maintenance_details',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['dateMillis'] as int?;
  }

  Future<void> insertEvent(MaintenanceEventRecord event) async {
    await _db.insert('maintenance_events', _eventToMap(event));
  }

  Future<void> updateEvent(MaintenanceEventRecord event) async {
    await _db.update(
      'maintenance_events',
      _eventToMap(event),
      where: 'id = ? AND userId = ?',
      whereArgs: [event.id, event.userId],
    );
  }

  Future<void> deleteEvent(int eventId, int userId) async {
    await _db.delete(
      'maintenance_events',
      where: 'id = ? AND userId = ?',
      whereArgs: [eventId, userId],
    );
  }

  Future<MaintenanceEventRecord?> eventById(int eventId, int userId) async {
    final rows = await _db.query(
      'maintenance_events',
      where: 'id = ? AND userId = ?',
      whereArgs: [eventId, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _eventFromRow(rows.first);
  }

  Future<List<MaintenanceEventRecord>> listEvents(int userId) async {
    final rows = await _db.query(
      'maintenance_events',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'event_time_millis DESC, id DESC',
    );
    return rows.map(_eventFromRow).toList();
  }

  UserRecord _userFromRow(Map<String, Object?> row) => UserRecord(
        id: row['id']! as int,
        username: row['username']! as String,
        password: row['password']! as String,
        fullName: row['fullName']! as String,
        poolSizeGallons: row['pool_size_gallons']! as int,
        poolSaltWater: (row['pool_salt_water']! as int) == 1,
        poolAboveGround: (row['pool_above_ground']! as int) == 1,
      );

  ChecklistRecord _checklistFromRow(Map<String, Object?> row) => ChecklistRecord(
        userId: row['userId']! as int,
        vacuum: (row['vacuum']! as int) == 1,
        cleanSkimmer: (row['clean_skimmer']! as int) == 1,
        addWater: (row['add_water']! as int) == 1,
        brushWalls: (row['brush_walls']! as int) == 1,
        chlorine: (row['chlorine']! as num).toDouble(),
        phUp: (row['ph_up']! as num).toDouble(),
        phDown: (row['ph_down']! as num).toDouble(),
        noPhos: (row['no_phos']! as num).toDouble(),
        customLinesJson: row['custom_lines_json'] as String?,
      );

  MaintenanceEventRecord _eventFromRow(Map<String, Object?> row) =>
      MaintenanceEventRecord(
        id: row['id']! as int,
        userId: row['userId']! as int,
        eventType: row['event_type']! as String,
        eventTimeMillis: row['event_time_millis']! as int,
        dateMillis: row['dateMillis']! as int,
        vacuum: (row['vacuum']! as int) == 1,
        cleanSkimmer: (row['clean_skimmer']! as int) == 1,
        addWater: (row['add_water']! as int) == 1,
        brushWalls: (row['brush_walls']! as int) == 1,
        chlorine: (row['chlorine']! as num).toDouble(),
        phUp: (row['ph_up']! as num).toDouble(),
        phDown: (row['ph_down']! as num).toDouble(),
        noPhos: (row['no_phos']! as num).toDouble(),
        lineItemsJson: row['line_items_json'] as String?,
      );

  Map<String, Object?> _eventToMap(MaintenanceEventRecord event) => {
        'userId': event.userId,
        'event_type': event.eventType,
        'event_time_millis': event.eventTimeMillis,
        'dateMillis': event.dateMillis,
        'vacuum': event.vacuum ? 1 : 0,
        'clean_skimmer': event.cleanSkimmer ? 1 : 0,
        'add_water': event.addWater ? 1 : 0,
        'brush_walls': event.brushWalls ? 1 : 0,
        'chlorine': event.chlorine,
        'ph_up': event.phUp,
        'ph_down': event.phDown,
        'no_phos': event.noPhos,
        'line_items_json': event.lineItemsJson,
      };
}
