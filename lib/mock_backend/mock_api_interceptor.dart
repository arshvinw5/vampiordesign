import 'package:dio/dio.dart';

import 'mock_auth_server.dart';

/// Short-circuits every Dio request into [MockAuthServer] after a simulated
/// network latency. It must be the **last** interceptor, so auth headers are
/// already attached. Remove it to talk to a real backend.
class MockApiInterceptor extends Interceptor {
  MockApiInterceptor(this._server, {this.latency = const Duration(milliseconds: 1500)});

  final MockAuthServer _server;
  final Duration latency;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await Future<void>.delayed(latency);
    try {
      final mock = await _server.handle(
        options.method,
        options.path,
        options.data,
        headers: options.headers,
      );
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: mock.statusCode,
        data: mock.body,
      );
      if (mock.ok) {
        handler.resolve(response, true);
      } else {
        handler.reject(
          DioException.badResponse(
            statusCode: mock.statusCode,
            requestOptions: options,
            response: response,
          ),
          true,
        );
      }
    } on MockConnectionError {
      handler.reject(
        DioException.connectionError(requestOptions: options, reason: 'Simulated offline'),
        true,
      );
    } catch (e, st) {
      handler.reject(DioException(requestOptions: options, error: e, stackTrace: st), true);
    }
  }
}
