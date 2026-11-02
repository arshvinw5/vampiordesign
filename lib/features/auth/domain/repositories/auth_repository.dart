import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, AuthSession>> login({
    required String identifier,
    required String password,
  });

  Future<Either<Failure, AuthSession>> register({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  });

  Future<Either<Failure, Unit>> requestPasswordReset(String identifier);

  /// Identifier saved by "Remember me", if any.
  Either<Failure, String?> getRememberedIdentifier();

  /// Saves [identifier], or clears it when `null`.
  Future<Either<Failure, Unit>> setRememberedIdentifier(String? identifier);
}
