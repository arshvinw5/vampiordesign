import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/preferences_data_source.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._prefs);
  final PreferencesDataSource _prefs;

  @override
  bool get isOnboardingSeen => _prefs.onboardingSeen;

  @override
  Future<Either<Failure, Unit>> markOnboardingSeen() async {
    try {
      await _prefs.setOnboardingSeen();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}

