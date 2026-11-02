import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RegisterUser implements UseCase<AuthSession, RegisterParams> {
  const RegisterUser(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSession>> call(RegisterParams params) => _repository.register(
        fullName: params.fullName,
        email: params.email,
        mobile: params.mobile,
        password: params.password,
      );
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
