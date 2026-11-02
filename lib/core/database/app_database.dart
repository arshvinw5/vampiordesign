import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../utils/password_hasher.dart';

/// Owns the SQLite connection and schema.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const fileName = 'vampior.db';
  static const usersTable = 'users';
  static const _version = 1;

  /// Seeded so the login flow can be demoed straight away.
  static const demoEmail = 'demo@vampior.com';
  static const demoMobile = '771234567';
  static const demoPassword = 'demo1234';

  /// Opens (and creates on first run) the database.
  ///
  /// Pass [factory] + [path] (e.g. `inMemoryDatabasePath`) in tests.
  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final dbFactory = factory ?? _platformFactory();
    final dbPath = path ?? p.join(await _defaultDirectory(dbFactory), fileName);
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: _version, onCreate: _onCreate),
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
    await db.execute('''
      CREATE TABLE $usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE COLLATE NOCASE,
        mobile TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.insert(usersTable, {
      'full_name': 'Demo User',
      'email': demoEmail,
      'mobile': demoMobile,
      'password_hash': PasswordHasher.hash(demoPassword),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> close() => db.close();
}
