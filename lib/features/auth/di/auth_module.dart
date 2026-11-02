import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/get_current_session.dart';
import '../domain/usecases/get_remembered_identifier.dart';
import '../domain/usecases/login_user.dart';
import '../domain/usecases/logout_user.dart';
import '../domain/usecases/register_user.dart';
import '../domain/usecases/request_password_reset.dart';
import '../domain/usecases/restore_session.dart';
import '../presentation/controllers/forgot_password_controller.dart';
import '../presentation/controllers/home_controller.dart';
import '../presentation/controllers/login_controller.dart';
import '../presentation/controllers/register_controller.dart';

void registerAuthModule(GetIt sl) {
  // Data
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<Dio>(), clock: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), tokens: sl(), prefs: sl()),
  );

  // Domain
  sl
    ..registerLazySingleton(() => LoginUser(sl()))
    ..registerLazySingleton(() => RegisterUser(sl()))
    ..registerLazySingleton(() => RequestPasswordReset(sl()))
    ..registerLazySingleton(() => GetRememberedIdentifier(sl()))
    ..registerLazySingleton(() => GetCurrentSession(sl()))
    ..registerLazySingleton(() => RestoreSession(sl()))
    ..registerLazySingleton(() => LogoutUser(sl()));

  // Presentation: factories, so each route gets fresh state that Provider
  // disposes when the route is popped.
  sl
    ..registerFactory(() => LoginController(loginUser: sl(), getRemembered: sl()))
    ..registerFactory(() => RegisterController(registerUser: sl()))
    ..registerFactory(() => ForgotPasswordController(requestReset: sl()))
    ..registerFactory(() => HomeController(getCurrentSession: sl(), logoutUser: sl(), clock: sl()));
}
