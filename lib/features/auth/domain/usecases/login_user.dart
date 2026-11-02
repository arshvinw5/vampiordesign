import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Logs in, then saves or clears the "Remember me" identifier.
class LoginUser implements UseCase<AuthSession, LoginParams> {
  const LoginUser(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSession>> call(LoginParams params) async {
    final result = await _repository.login(
      identifier: params.identifier,
      password: params.password,
    );
    if (result.isRight()) {
      // Failing to save the preference must not block a successful login.
      await _repository.setRememberedIdentifier(params.rememberMe ? params.identifier : null);
    }
    return result;
  }
}

class LoginParams extends Equatable {
  const LoginParams({required this.identifier, required this.password, required this.rememberMe});
  final String identifier;
  final String password;
  final bool rememberMe;

  @override
  List<Object?> get props => [identifier, password, rememberMe];
}
