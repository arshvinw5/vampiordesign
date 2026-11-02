import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

abstract interface class OnboardingRepository {
  bool get isOnboardingSeen;
  Future<Either<Failure, Unit>> markOnboardingSeen();
}
