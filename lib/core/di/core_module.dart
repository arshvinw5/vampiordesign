import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_tokens.dart';
import '../auth/session_events.dart';
import '../storage/preferences_data_source.dart';
import '../storage/token_storage.dart';
import 'service_locator.dart';

/// App-wide infrastructure with no feature knowledge.
Future<void> registerCoreModule(GetIt sl, DependencyOverrides o) async {
  sl.registerSingleton<Clock>(o.clock);

  // Non-secret flags (onboarding seen, remembered identifier).
  sl.registerSingleton<SharedPreferences>(o.prefs ?? await SharedPreferences.getInstance());
  sl.registerLazySingleton(() => PreferencesDataSource(sl()));

  // Secrets (access/refresh tokens): Keychain / Keystore / libsecret.
  sl.registerLazySingleton<TokenStorage>(() => o.tokenStorage ?? SecureTokenStorage());

  sl.registerLazySingleton(SessionEvents.new, dispose: (e) => e.dispose());
}
