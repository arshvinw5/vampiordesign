import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_endpoints.dart';

abstract final class DioClient {
  /// Builds the app's Dio instance. [interceptors] go after logging, so a
  /// mock interceptor can answer requests before they hit the network.
  static Dio create({List<Interceptor> interceptors = const []}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, logPrint: (o) => debugPrint('$o')),
      );
    }
    dio.interceptors.addAll(interceptors);
    return dio;
  }
}
