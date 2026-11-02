import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Synchronous: the value is already in memory once prefs are loaded.
class GetRememberedIdentifier {
  const GetRememberedIdentifier(this._repository);
  final AuthRepository _repository;

  Either<Failure, String?> call() => _repository.getRememberedIdentifier();
}
