import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;

  /// 9 national digits (Sri Lanka, without +94).
  final String mobile;
  final DateTime createdAt;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  @override
  List<Object?> get props => [id, fullName, email, mobile, createdAt];
}
