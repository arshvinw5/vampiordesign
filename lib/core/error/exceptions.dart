/// Data-layer exceptions. Repositories convert these into `Failure`s.
class CacheException implements Exception {
  const CacheException([this.message = 'Local storage error']);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}

class DuplicateUserException implements Exception {
  const DuplicateUserException(this.field);

  /// `email` or `mobile`.
  final String field;

  String get message =>
      field == 'mobile' ? 'Mobile number already registered' : 'Email already registered';

  @override
  String toString() => 'DuplicateUserException: $field';
}
