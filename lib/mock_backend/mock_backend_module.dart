import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../core/di/network_module.dart';
import '../core/di/service_locator.dart';
import 'database/app_database.dart';
import 'mock_api_interceptor.dart';
import 'mock_auth_server.dart';
import 'security/mock_token_service.dart';
import 'stores/session_store.dart';
import 'stores/user_store.dart';

/// Registers the fake backend: its SQLite database, stores, token service,
/// [MockAuthServer], and the Dio interceptor that routes requests to it.
///
/// The app only reaches this through HTTP-shaped calls, so replacing it
/// with a real API means removing this module's registration.
Future<void> registerMockBackendModule(GetIt sl, DependencyOverrides o) async {
  final needsDb = o.userStore == null || o.sessionStore == null;
  if (needsDb) {
    sl.registerSingleton<AppDatabase>(await AppDatabase.open(), dispose: (db) => db.close());
  }
  sl.registerLazySingleton<UserStore>(() => o.userStore ?? SqliteUserStore(sl()));
  sl.registerLazySingleton<SessionStore>(() => o.sessionStore ?? SqliteSessionStore(sl()));

  sl.registerLazySingleton(() => MockTokenService(accessTtl: o.accessTokenTtl, clock: sl()));
  sl.registerLazySingleton(() => MockAuthServer(users: sl(), sessions: sl(), tokens: sl()));
  sl.registerLazySingleton<Interceptor>(
    () => MockApiInterceptor(sl(), latency: o.apiLatency),
    instanceName: transportInterceptor,
  );
}
