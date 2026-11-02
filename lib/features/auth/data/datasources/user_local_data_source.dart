import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/validation/validators.dart';
import '../models/user_record.dart';

/// SQLite access for the `users` table.
abstract interface class UserLocalDataSource {
  Future<UserRecord> insertUser({
    required String fullName,
    required String email,
    required String mobile,
    required String passwordHash,
  });

  /// Finds a user by email (case-insensitive) or Sri Lankan mobile in any
  /// common format (`0771234567`, `+94 77 123 4567`, `771234567`).
  Future<UserRecord?> findByIdentifier(String identifier);
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  UserLocalDataSourceImpl(this._database);

  final AppDatabase _database;
  Database get _db => _database.db;

  @override
  Future<UserRecord> insertUser({
    required String fullName,
    required String email,
    required String mobile,
    required String passwordHash,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    // Check first so we can say which field clashed.
    if (await _findOne('email = ?', normalizedEmail) != null) {
      throw const DuplicateUserException('email');
    }
    if (await _findOne('mobile = ?', mobile) != null) {
      throw const DuplicateUserException('mobile');
    }
    final row = {
      'full_name': fullName.trim(),
      'email': normalizedEmail,
      'mobile': mobile,
      'password_hash': passwordHash,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      final id = await _db.insert(AppDatabase.usersTable, row);
      return UserRecord.fromRow({...row, 'id': id});
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw DuplicateUserException(e.toString().contains('mobile') ? 'mobile' : 'email');
      }
      rethrow;
    }
  }

  @override
  Future<UserRecord?> findByIdentifier(String identifier) {
    final id = identifier.trim();
    if (Validators.isEmail(id)) return _findOne('email = ?', id.toLowerCase());
    return _findOne('mobile = ?', LkMobile.parse(id));
  }

  Future<UserRecord?> _findOne(String where, Object arg) async {
    final rows = await _db.query(
      AppDatabase.usersTable,
      where: where,
      whereArgs: [arg],
      limit: 1,
    );
    return rows.isEmpty ? null : UserRecord.fromRow(rows.first);
  }
}
