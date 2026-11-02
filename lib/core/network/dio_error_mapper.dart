import 'package:dio/dio.dart';

import '../error/failures.dart';

/// Converts transport errors into domain [Failure]s.
abstract final class DioErrorMapper {
  static Failure map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        return _fromStatus(e.response?.statusCode, _message(e.response?.data));
      case DioExceptionType.transformTimeout:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const ServerFailure();
    }
  }

  static Failure _fromStatus(int? status, String? message) => switch (status) {
        401 => InvalidCredentialsFailure(message ?? const InvalidCredentialsFailure().message),
        404 => UserNotFoundFailure(message ?? const UserNotFoundFailure().message),
        409 => ConflictFailure(message ?? const ConflictFailure().message),
        _ => const ServerFailure(),
      };

  static String? _message(Object? data) =>
      data is Map && data['message'] is String ? data['message'] as String : null;
}
