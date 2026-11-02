import 'package:dio/dio.dart';

import '../../../../core/auth/auth_tokens.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_requests.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Talks to the auth REST API. Throws [DioException] on failure.
abstract interface class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginRequest request);
  Future<AuthResponseModel> register(RegisterRequest request);
  Future<void> requestPasswordReset(ForgotPasswordRequest request);

  /// `GET /auth/me`. Protected, so `AuthInterceptor` adds the Bearer token.
  Future<UserModel> me();

  /// `POST /auth/logout`: revokes [refreshToken] on the server.
  Future<void> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio, {this._clock = systemClock});

  final Dio _dio;
  final Clock _clock;

  static final _public = Options(extra: ApiEndpoints.publicRequest);

  @override
  Future<AuthResponseModel> login(LoginRequest request) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: request.toJson(),
      options: _public,
    );
    return AuthResponseModel.fromJson(res.data!, now: _clock());
  }

  @override
  Future<AuthResponseModel> register(RegisterRequest request) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: request.toJson(),
      options: _public,
    );
    return AuthResponseModel.fromJson(res.data!, now: _clock());
  }

  @override
  Future<void> requestPasswordReset(ForgotPasswordRequest request) async {
    await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.forgotPassword,
      data: request.toJson(),
      options: _public,
    );
  }

  @override
  Future<UserModel> me() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
    return UserModel.fromJson(res.data!['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.logout,
      data: {'refreshToken': refreshToken},
      options: _public,
    );
  }
}
