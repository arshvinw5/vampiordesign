import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../security/password_hasher.dart';

/// The mock backend's SQLite database (what a real server would keep in
/// its own DB). The app never queries it directly, only over the API.
///
/// Schema history:
/// - v1: `users`
/// - v2: `sessions` (refresh tokens, rotated and revocable)
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const fileName = 'vampior.db';
  static const usersTable = 'users';
  static const sessionsTable = 'sessions';
  static const version = 2;

  /// Seeded so the login flow can be demoed straight away.
  static const demoEmail = 'demo@vampior.com';
  static const demoMobile = '771234567';
  static const demoPassword = 'demo1234';

  /// Opens (and creates or migrates) the database.
  ///
  /// Pass [factory] + [path] (e.g. `inMemoryDatabasePath`) in tests.
  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? _platformFactory();
    final dbPath = path ?? p.join(await _defaultDirectory(dbFactory), fileName);
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return AppDatabase._(db);
  }

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

  /// Mobile: sqflite's standard location. Desktop: the per-user app-support
  /// folder (ffi's default would be `.dart_tool/` under the working directory).
  static Future<String> _defaultDirectory(DatabaseFactory factory) async {
    if (_isDesktop) return (await getApplicationSupportDirectory()).path;
    return factory.getDatabasesPath();
  }

  static DatabaseFactory _platformFactory() {
    if (_isDesktop) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return databaseFactorySqflitePlugin;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createUsers(db);
    await _createSessions(db);
    await db.insert(usersTable, {
      'full_name': 'Demo User',
      'email': demoEmail,
      'mobile': demoMobile,
      'password_hash': PasswordHasher.hash(demoPassword),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    if (from < 2) await _createSessions(db);
  }

  static Future<void> _createUsers(Database db) => db.execute('''
    CREATE TABLE $usersTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      full_name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE COLLATE NOCASE,
      mobile TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  static Future<void> _createSessions(Database db) => db.execute('''
    CREATE TABLE $sessionsTable (
      refresh_token TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES $usersTable(id) ON DELETE CASCADE,
      expires_at TEXT NOT NULL,
      revoked INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )
  ''');

  Future<void> close() => db.close();
}
