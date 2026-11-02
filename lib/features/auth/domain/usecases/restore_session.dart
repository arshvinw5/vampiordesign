import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Auto-login at launch from the tokens in secure storage.
class RestoreSession implements UseCase<AuthSession, NoParams> {
  const RestoreSession(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSession>> call(NoParams params) => _repository.restoreSession();
}
