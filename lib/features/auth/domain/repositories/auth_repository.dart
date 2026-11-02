import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  /// Signs in and stores the token pair securely.
  Future<Either<Failure, AuthSession>> login({
    required String identifier,
    required String password,
  });

  /// Creates the account, signs in, and stores the token pair securely.
  Future<Either<Failure, AuthSession>> register({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  });

  Future<Either<Failure, Unit>> requestPasswordReset(String identifier);

  /// Fetches the profile with the stored access token (auto-refreshed if
  /// needed) and returns it together with the current tokens.
  Future<Either<Failure, AuthSession>> getCurrentSession();

  /// Auto-login on launch: if tokens are stored and the user chose to stay
  /// signed in, validates them via `/auth/me` (refreshing if needed).
  /// Returns [SessionExpiredFailure] when there is nothing to restore.
  Future<Either<Failure, AuthSession>> restoreSession();

  /// Saves whether the next launch may restore the session.
  Future<Either<Failure, Unit>> setKeepSignedIn(bool value);

  /// Revokes the refresh token server-side and clears stored tokens.
  /// Local tokens are cleared even if the server call fails.
  Future<Either<Failure, Unit>> logout();

  /// Identifier saved by "Remember me", if any.
  Either<Failure, String?> getRememberedIdentifier();

  /// Saves [identifier], or clears it when `null`.
  Future<Either<Failure, Unit>> setRememberedIdentifier(String? identifier);
}
