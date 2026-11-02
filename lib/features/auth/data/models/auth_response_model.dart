import '../../../../core/auth/auth_tokens.dart';
import '../../domain/entities/auth_session.dart';
import 'user_model.dart';

/// `{user, accessToken, refreshToken, tokenType, expiresIn}` from login/register.
class AuthResponseModel extends AuthSession {
  const AuthResponseModel({required UserModel super.user, required super.tokens});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json, {required DateTime now}) =>
      AuthResponseModel(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(json, now: now),
      );
}
