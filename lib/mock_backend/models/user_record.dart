/// A full `users` row, including the password hash. Only the mock backend
/// sees this; the API exposes [toJson] (no hash).
class UserRecord {
  const UserRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.passwordHash,
    required this.createdAt,
  });

  factory UserRecord.fromRow(Map<String, Object?> row) => UserRecord(
    id: row['id']! as int,
    fullName: row['full_name']! as String,
    email: row['email']! as String,
    mobile: row['mobile']! as String,
    passwordHash: row['password_hash']! as String,
    createdAt: DateTime.parse(row['created_at']! as String),
  );

  final int id;
  final String fullName;
  final String email;
  final String mobile;
  final String passwordHash;
  final DateTime createdAt;

  /// Public API representation.
  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'mobile': mobile,
    'createdAt': createdAt.toIso8601String(),
  };
}
