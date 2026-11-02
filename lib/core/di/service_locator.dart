import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/di/auth_module.dart';
import '../../features/onboarding/di/onboarding_module.dart';
import '../../features/startup/di/startup_module.dart';
import '../../mock_backend/mock_backend_module.dart';
import '../../mock_backend/stores/session_store.dart';
import '../../mock_backend/stores/user_store.dart';
import '../auth/auth_tokens.dart';
import '../storage/token_storage.dart';
import 'core_module.dart';
import 'network_module.dart';

/// The app's service locator. Only the DI modules and `AppRouter` touch it.
/// Everything else receives its dependencies through constructors.
final sl = GetIt.instance;

/// Test and demo seams. Production uses the defaults.
class DependencyOverrides {
  const DependencyOverrides({
    this.prefs,
    this.tokenStorage,
    this.userStore,
    this.sessionStore,
    this.apiLatency = const Duration(milliseconds: 1500),
    this.accessTokenTtl = const Duration(seconds: 60),
    this.clock = systemClock,
  });

  final SharedPreferences? prefs;
  final TokenStorage? tokenStorage;

  /// In-memory stores replace the SQLite database (needed in widget tests).
  final UserStore? userStore;
  final SessionStore? sessionStore;
  final Duration apiLatency;
  final Duration accessTokenTtl;
  final Clock clock;
}

/// Builds the object graph, in dependency order:
///
/// 1. **core**: clock, shared_preferences, secure token storage, session events
/// 2. **mock backend**: SQLite, stores, token service, fake server and its
///    Dio interceptor. Delete this line to talk to a real API.
/// 3. **network**: Dio clients and [AuthInterceptor]
/// 4. **features**: onboarding, auth, then startup (which uses both)
Future<void> configureDependencies([
  DependencyOverrides overrides = const DependencyOverrides(),
]) async {
  await registerCoreModule(sl, overrides);
  await registerMockBackendModule(sl, overrides);
  registerNetworkModule(sl);
  registerOnboardingModule(sl);
  registerAuthModule(sl);
  registerStartupModule(sl);
}

/// Disposes singletons (closes the DB and streams) and clears the registry.
Future<void> resetDependencies() => sl.reset();
