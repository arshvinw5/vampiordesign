import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/storage/preferences_data_source.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_requests.dart';

/// Coordinates the remote API, secure token storage and preferences.
/// Every exception is converted to a [Failure] here, so nothing above the
/// data layer ever sees a `DioException` or `CacheException`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._remote, required this._tokens, required this._prefs});

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;
  final PreferencesDataSource _prefs;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String identifier,
    required String password,
  }) =>
      _signIn(() => _remote.login(LoginRequest(identifier: identifier.trim(), password: password)));

  @override
  Future<Either<Failure, AuthSession>> register({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  }) => _signIn(
    () => _remote.register(
      RegisterRequest(
        fullName: fullName.trim(),
        email: email.trim(),
        mobile: mobile,
        password: password,
      ),
    ),
  );

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String identifier) => _call(() async {
    await _remote.requestPasswordReset(ForgotPasswordRequest(identifier.trim()));
    return unit;
  });

  @override
  Future<Either<Failure, AuthSession>> getCurrentSession() async {
    final result = await _call(() async {
      final user = await _remote.me();
      // Read after the call: AuthInterceptor may have rotated the tokens.
      final tokens = await _tokens.read();
      if (tokens == null) throw const _NoSession();
      return AuthSession(user: user, tokens: tokens);
    });
    // On a protected endpoint, 401 means the session (not the password) is bad.
    return result.leftMap(
      (f) => f is InvalidCredentialsFailure ? const SessionExpiredFailure() : f,
    );
  }

  @override
  Future<Either<Failure, AuthSession>> restoreSession() async {
    try {
      if (await _tokens.read() == null) return const Left(SessionExpiredFailure());
      if (!_prefs.keepSignedIn) {
        // The user didn't ask to stay signed in: drop the leftover session.
        await _tokens.clear();
        return const Left(SessionExpiredFailure());
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
    return getCurrentSession();
  }

  @override
  Future<Either<Failure, Unit>> setKeepSignedIn(bool value) async {
    try {
      await _prefs.setKeepSignedIn(value);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      final tokens = await _tokens.read();
      if (tokens != null) {
        try {
          await _remote.logout(tokens.refreshToken);
        } on DioException {
          // Offline or server error: still sign out locally.
        }
      }
      await _tokens.clear();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Either<Failure, String?> getRememberedIdentifier() {
    try {
      return Right(_prefs.rememberedIdentifier);
    } on Exception {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setRememberedIdentifier(String? identifier) async {
    try {
      await _prefs.setRememberedIdentifier(identifier?.trim());
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  /// Runs a login/register call and persists the returned tokens.
  Future<Either<Failure, AuthSession>> _signIn(Future<AuthSession> Function() request) =>
      _call(() async {
        final session = await request();
        await _tokens.save(session.tokens);
        return session;
      });

  Future<Either<Failure, T>> _call<T>(Future<T> Function() request) async {
    try {
      return Right(await request());
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } on CacheException {
      return const Left(CacheFailure('Could not access secure storage'));
    } on _NoSession {
      return const Left(SessionExpiredFailure());
    } on FormatException {
      return const Left(ServerFailure('Unexpected response from server'));
    } on TypeError {
      return const Left(ServerFailure('Unexpected response from server'));
    }
  }
}

class _NoSession implements Exception {
  const _NoSession();
}
