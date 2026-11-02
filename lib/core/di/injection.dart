import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/user_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_remembered_identifier.dart';
import '../../features/auth/domain/usecases/login_user.dart';
import '../../features/auth/domain/usecases/register_user.dart';
import '../../features/auth/domain/usecases/request_password_reset.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/onboarding_usecases.dart';
import '../database/app_database.dart';
import '../network/dio_client.dart';
import '../network/mock/mock_api_interceptor.dart';
import '../network/mock/mock_auth_server.dart';
import '../storage/preferences_data_source.dart';

/// Composition root: builds the object graph once at startup and exposes
/// the use cases to the widget tree through Provider.
///
/// Dependencies point inward: presentation → domain ← data.
class AppDependencies {
  AppDependencies._({
    required this.dio,
    required this.authRepository,
    required this.onboardingRepository,
  });

  final Dio dio;
  final AuthRepository authRepository;
  final OnboardingRepository onboardingRepository;

  /// Override any piece for tests: [users] replaces the SQLite store,
  /// [database] supplies an already-open (e.g. in-memory) DB.
  static Future<AppDependencies> init({
    SharedPreferences? prefs,
    AppDatabase? database,
    UserLocalDataSource? users,
    Duration apiLatency = const Duration(milliseconds: 1500),
  }) async {
    final preferences = PreferencesDataSource(prefs ?? await SharedPreferences.getInstance());
    final userStore = users ?? UserLocalDataSourceImpl(database ?? await AppDatabase.open());

    // Data layer: the mock "backend" lives behind a Dio interceptor.
    final dio = DioClient.create(
      interceptors: [MockApiInterceptor(MockAuthServer(userStore), latency: apiLatency)],
    );

    return AppDependencies._(
      dio: dio,
      authRepository: AuthRepositoryImpl(AuthRemoteDataSourceImpl(dio), preferences),
      onboardingRepository: OnboardingRepositoryImpl(preferences),
    );
  }

  bool get onboardingSeen => CheckOnboardingSeen(onboardingRepository)();

  /// Use cases exposed to presentation-layer controllers.
  List<SingleChildWidget> get providers => [
        Provider(create: (_) => LoginUser(authRepository)),
        Provider(create: (_) => RegisterUser(authRepository)),
        Provider(create: (_) => RequestPasswordReset(authRepository)),
        Provider(create: (_) => GetRememberedIdentifier(authRepository)),
        Provider(create: (_) => CompleteOnboarding(onboardingRepository)),
      ];
}
