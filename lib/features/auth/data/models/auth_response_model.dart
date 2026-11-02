import '../../domain/entities/auth_session.dart';
import 'user_model.dart';

class AuthResponseModel extends AuthSession {
  const AuthResponseModel({required UserModel super.user, required super.token});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) => AuthResponseModel(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        token: json['token'] as String,
      );
}
