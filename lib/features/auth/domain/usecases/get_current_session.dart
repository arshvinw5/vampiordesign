import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Loads the signed-in profile through the protected `/auth/me` endpoint.
class GetCurrentSession implements UseCase<AuthSession, NoParams> {
  const GetCurrentSession(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSession>> call(NoParams params) => _repository.getCurrentSession();
}
