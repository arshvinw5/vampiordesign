/// A `sessions` row: one refresh token. Rotated on every refresh (the old
/// row is revoked), and revoked on logout.
class SessionRecord {
  const SessionRecord({
    required this.refreshToken,
    required this.userId,
    required this.expiresAt,
    required this.revoked,
  });

  factory SessionRecord.fromRow(Map<String, Object?> row) => SessionRecord(
    refreshToken: row['refresh_token']! as String,
    userId: row['user_id']! as int,
    expiresAt: DateTime.parse(row['expires_at']! as String),
    revoked: (row['revoked']! as int) == 1,
  );

  final String refreshToken;
  final int userId;
  final DateTime expiresAt;
  final bool revoked;

  bool isUsable(DateTime now) => !revoked && now.isBefore(expiresAt);
}
