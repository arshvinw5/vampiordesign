import 'package:get_it/get_it.dart';

import '../data/repositories/onboarding_repository_impl.dart';
import '../domain/repositories/onboarding_repository.dart';
import '../domain/usecases/onboarding_usecases.dart';
import '../presentation/controllers/onboarding_controller.dart';

void registerOnboardingModule(GetIt sl) {
  // Data
  sl.registerLazySingleton<OnboardingRepository>(() => OnboardingRepositoryImpl(sl()));

  // Domain
  sl.registerLazySingleton(() => CheckOnboardingSeen(sl()));
  sl.registerLazySingleton(() => CompleteOnboarding(sl()));

  // Presentation: a fresh controller per screen.
  sl.registerFactory(() => OnboardingController(completeOnboarding: sl()));
}
