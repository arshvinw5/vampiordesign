import '../database/app_database.dart';
import '../models/session_record.dart';

/// Backend persistence for refresh-token sessions.
abstract interface class SessionStore {
  Future<void> create({
    required String refreshToken,
    required int userId,
    required DateTime expiresAt,
  });

  Future<SessionRecord?> find(String refreshToken);

  /// Idempotent; unknown tokens are ignored.
  Future<void> revoke(String refreshToken);
}

class SqliteSessionStore implements SessionStore {
  SqliteSessionStore(this._database);
  final AppDatabase _database;

  @override
  Future<void> create({
    required String refreshToken,
    required int userId,
    required DateTime expiresAt,
  }) async {
    await _database.db.insert(AppDatabase.sessionsTable, {
      'refresh_token': refreshToken,
      'user_id': userId,
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'revoked': 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<SessionRecord?> find(String refreshToken) async {
    final rows = await _database.db.query(
      AppDatabase.sessionsTable,
      where: 'refresh_token = ?',
      whereArgs: [refreshToken],
      limit: 1,
    );
    return rows.isEmpty ? null : SessionRecord.fromRow(rows.first);
  }

  @override
  Future<void> revoke(String refreshToken) async {
    await _database.db.update(
      AppDatabase.sessionsTable,
      {'revoked': 1},
      where: 'refresh_token = ?',
      whereArgs: [refreshToken],
    );
  }
}
