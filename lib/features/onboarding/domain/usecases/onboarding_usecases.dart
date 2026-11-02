import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/onboarding_repository.dart';

/// Decides the start screen: onboarding only on first launch.
class CheckOnboardingSeen {
  const CheckOnboardingSeen(this._repository);
  final OnboardingRepository _repository;

  bool call() => _repository.isOnboardingSeen;
}

class CompleteOnboarding implements UseCase<Unit, NoParams> {
  const CompleteOnboarding(this._repository);
  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.markOnboardingSeen();
}
