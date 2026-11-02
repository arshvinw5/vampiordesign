import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';

/// Instance names for the two Dio clients.
abstract final class DioClients {
  /// No auth handling: used by [AuthInterceptor] to refresh and retry.
  static const bare = 'bareDio';
}

/// Instance name under which a backend module may register a transport
/// interceptor (the mock API). If none is registered, Dio uses real HTTP.
const transportInterceptor = 'transportInterceptor';

/// Interceptor order on the main client:
/// `LogInterceptor → AuthInterceptor → (transport, e.g. MockApiInterceptor)`.
void registerNetworkModule(GetIt sl) {
  List<Interceptor> transport() => [
    if (sl.isRegistered<Interceptor>(instanceName: transportInterceptor))
      sl<Interceptor>(instanceName: transportInterceptor),
  ];

  sl.registerLazySingleton<Dio>(
    () => DioClient.create(interceptors: transport()),
    instanceName: DioClients.bare,
  );

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      storage: sl(),
      bareDio: sl<Dio>(instanceName: DioClients.bare),
      events: sl(),
      clock: sl(),
    ),
  );

  sl.registerLazySingleton<Dio>(
    () => DioClient.create(interceptors: [sl<AuthInterceptor>(), ...transport()]),
  );
}
