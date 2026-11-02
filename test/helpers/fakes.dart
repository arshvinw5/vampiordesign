import 'package:vampiordesigns/core/auth/auth_tokens.dart';
import 'package:vampiordesigns/core/storage/token_storage.dart';
import 'package:vampiordesigns/core/utils/phone_formatter.dart';
import 'package:vampiordesigns/core/validation/validators.dart';
import 'package:vampiordesigns/mock_backend/database/app_database.dart';
import 'package:vampiordesigns/mock_backend/models/session_record.dart';
import 'package:vampiordesigns/mock_backend/models/user_record.dart';
import 'package:vampiordesigns/mock_backend/security/password_hasher.dart';
import 'package:vampiordesigns/mock_backend/stores/session_store.dart';
import 'package:vampiordesigns/mock_backend/stores/user_store.dart';

/// In-memory stand-ins for the SQLite stores, for widget tests (sqflite's
/// real async I/O doesn't run inside the fake-async test zone).
class FakeUserStore implements UserStore {
  FakeUserStore() {
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

  @override
  Future<UserRecord?> findById(int id) async {
    for (final r in _rows) {
      if (r.id == id) return r;
    }
    return null;
  }
}

class FakeSessionStore implements SessionStore {
  final sessions = <String, SessionRecord>{};

  @override
  Future<void> create({
    required String refreshToken,
    required int userId,
    required DateTime expiresAt,
  }) async {
    sessions[refreshToken] = SessionRecord(
      refreshToken: refreshToken,
      userId: userId,
      expiresAt: expiresAt,
      revoked: false,
    );
  }

  @override
  Future<SessionRecord?> find(String refreshToken) async => sessions[refreshToken];

  @override
  Future<void> revoke(String refreshToken) async {
    final s = sessions[refreshToken];
    if (s == null) return;
    sessions[refreshToken] = SessionRecord(
      refreshToken: s.refreshToken,
      userId: s.userId,
      expiresAt: s.expiresAt,
      revoked: true,
    );
  }
}

/// Stand-in for flutter_secure_storage.
class InMemoryTokenStorage implements TokenStorage {
  AuthTokens? tokens;
  int saves = 0;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> save(AuthTokens t) async {
    tokens = t;
    saves++;
  }

  @override
  Future<void> clear() async => tokens = null;
}

/// A clock the test can move forward.
class TestClock {
  TestClock([DateTime? start]) : now = start ?? DateTime.utc(2026, 11, 2, 12);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}
