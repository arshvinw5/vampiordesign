import 'package:get_it/get_it.dart';

import '../presentation/controllers/startup_controller.dart';

/// Depends on use cases from the onboarding and auth modules, so it is
/// registered after both.
void registerStartupModule(GetIt sl) {
  sl.registerFactory(() => StartupController(checkOnboardingSeen: sl(), restoreSession: sl()));
}
