import 'package:sqflite/sqflite.dart';

import '../../core/utils/phone_formatter.dart';
import '../../core/validation/validators.dart';
import '../database/app_database.dart';
import '../models/user_record.dart';

/// Thrown when registering an email or mobile that already exists.
class DuplicateUserException implements Exception {
  const DuplicateUserException(this.field);

  /// `email` or `mobile`.
  final String field;

  String get message =>
      field == 'mobile' ? 'Mobile number already registered' : 'Email already registered';

  @override
  String toString() => 'DuplicateUserException: $field';
}

/// Backend persistence for users.
abstract interface class UserStore {
  Future<UserRecord> insertUser({
    required String fullName,
    required String email,
    required String mobile,
    required String passwordHash,
  });

  /// Finds a user by email (case-insensitive) or Sri Lankan mobile in any
  /// common format (`0771234567`, `+94 77 123 4567`, `771234567`).
  Future<UserRecord?> findByIdentifier(String identifier);

  Future<UserRecord?> findById(int id);
}

class SqliteUserStore implements UserStore {
  SqliteUserStore(this._database);

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

  @override
  Future<UserRecord?> findById(int id) => _findOne('id = ?', id);

  Future<UserRecord?> _findOne(String where, Object arg) async {
    final rows = await _db.query(AppDatabase.usersTable, where: where, whereArgs: [arg], limit: 1);
    return rows.isEmpty ? null : UserRecord.fromRow(rows.first);
  }
}
