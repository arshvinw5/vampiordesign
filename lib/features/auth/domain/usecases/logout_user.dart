import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Revokes the session server-side and wipes tokens from secure storage.
class LogoutUser implements UseCase<Unit, NoParams> {
  const LogoutUser(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.logout();
}
