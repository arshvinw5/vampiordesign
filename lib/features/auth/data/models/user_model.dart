import '../../domain/entities/user.dart';

/// JSON DTO for a user as returned by the API.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.mobile,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    fullName: json['fullName'] as String,
    email: json['email'] as String,
    mobile: json['mobile'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'mobile': mobile,
    'createdAt': createdAt.toIso8601String(),
  };
}
