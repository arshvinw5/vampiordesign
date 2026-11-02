import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class RequestPasswordReset implements UseCase<Unit, String> {
  const RequestPasswordReset(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String identifier) =>
      _repository.requestPasswordReset(identifier);
}
