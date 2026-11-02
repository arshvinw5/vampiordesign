import 'package:vampiordesigns/core/database/app_database.dart';
import 'package:vampiordesigns/core/error/exceptions.dart';
import 'package:vampiordesigns/core/utils/password_hasher.dart';
import 'package:vampiordesigns/core/utils/phone_formatter.dart';
import 'package:vampiordesigns/core/validation/validators.dart';
import 'package:vampiordesigns/features/auth/data/datasources/user_local_data_source.dart';
import 'package:vampiordesigns/features/auth/data/models/user_record.dart';

/// In-memory stand-in for the SQLite store, for widget tests (sqflite's
/// real async I/O doesn't run inside the fake-async test zone).
class FakeUserDataSource implements UserLocalDataSource {
  FakeUserDataSource() {
    _rows.add(
      UserRecord(
        id: 1,
        fullName: 'Demo User',
        email: AppDatabase.demoEmail,
        mobile: AppDatabase.demoMobile,
        passwordHash: PasswordHasher.hash(AppDatabase.demoPassword),
        createdAt: DateTime.utc(2026),
      ),
    );
  }

  final _rows = <UserRecord>[];
  List<UserRecord> get rows => List.unmodifiable(_rows);

  @override
  Future<UserRecord> insertUser({
    required String fullName,
    required String email,
    required String mobile,
    required String passwordHash,
  }) async {
    final e = email.trim().toLowerCase();
    if (_rows.any((r) => r.email == e)) throw const DuplicateUserException('email');
    if (_rows.any((r) => r.mobile == mobile)) throw const DuplicateUserException('mobile');
    final rec = UserRecord(
      id: _rows.length + 1,
      fullName: fullName.trim(),
      email: e,
      mobile: mobile,
      passwordHash: passwordHash,
      createdAt: DateTime.now().toUtc(),
    );
    _rows.add(rec);
    return rec;
  }

  @override
  Future<UserRecord?> findByIdentifier(String identifier) async {
    final id = identifier.trim();
    final isEmail = Validators.isEmail(id);
    final key = isEmail ? id.toLowerCase() : LkMobile.parse(id);
    for (final r in _rows) {
      if ((isEmail ? r.email : r.mobile) == key) return r;
    }
    return null;
  }
}
