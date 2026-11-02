import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RegisterUser implements UseCase<AuthSession, RegisterParams> {
  const RegisterUser(this._repository);
  final AuthRepository _repository;

  /// Creates the account and signs in. New accounts stay signed in.
  @override
  Future<Either<Failure, AuthSession>> call(RegisterParams params) async {
    final result = await _repository.register(
      fullName: params.fullName,
      email: params.email,
      mobile: params.mobile,
      password: params.password,
    );
    if (result.isRight()) await _repository.setKeepSignedIn(true);
    return result;
  }
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.password,
  });
  final String fullName;
  final String email;

  /// 9 national digits.
  final String mobile;
  final String password;

  @override
  List<Object?> get props => [fullName, email, mobile, password];
}
