import 'package:equatable/equatable.dart';

/// Domain-level error returned on the left side of `Either`.
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No connection. Check your internet and try again.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on our side. Please try again.']);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([super.message = 'Incorrect email/mobile or password']);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure([super.message = 'No account found for that email or mobile number']);
}

/// Duplicate email / mobile on registration.
class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'An account with these details already exists']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Could not access local storage']);
}

/// Access and refresh tokens are no longer valid; the user must sign in again.
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.message = 'Your session has expired. Please log in again.']);
}
