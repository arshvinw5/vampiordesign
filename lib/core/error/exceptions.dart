/// Data-layer exceptions. Repositories convert these into `Failure`s.
class CacheException implements Exception {
  const CacheException([this.message = 'Local storage error']);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}
