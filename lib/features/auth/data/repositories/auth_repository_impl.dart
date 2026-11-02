import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/storage/preferences_data_source.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_requests.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._prefs);

  final AuthRemoteDataSource _remote;
  final PreferencesDataSource _prefs;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String identifier,
    required String password,
  }) =>
      _call(() => _remote.login(LoginRequest(identifier: identifier.trim(), password: password)));

  @override
  Future<Either<Failure, AuthSession>> register({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  }) =>
      _call(
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

  Future<Either<Failure, T>> _call<T>(Future<T> Function() request) async {
    try {
      return Right(await request());
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } on FormatException {
      return const Left(ServerFailure('Unexpected response from server'));
    } on TypeError {
      return const Left(ServerFailure('Unexpected response from server'));
    }
  }
}
