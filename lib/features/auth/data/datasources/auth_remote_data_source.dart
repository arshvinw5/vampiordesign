import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/auth_requests.dart';
import '../models/auth_response_model.dart';

/// Talks to the auth REST API. Throws [DioException] on failure.
abstract interface class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginRequest request);
  Future<AuthResponseModel> register(RegisterRequest request);
  Future<void> requestPasswordReset(ForgotPasswordRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthResponseModel> login(LoginRequest request) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.login, data: request.toJson());
    return AuthResponseModel.fromJson(res.data!);
  }

  @override
  Future<AuthResponseModel> register(RegisterRequest request) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.register, data: request.toJson());
    return AuthResponseModel.fromJson(res.data!);
  }

  @override
  Future<void> requestPasswordReset(ForgotPasswordRequest request) async {
    await _dio.post<Map<String, dynamic>>(ApiEndpoints.forgotPassword, data: request.toJson());
  }
}
