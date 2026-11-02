import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../error/failures.dart';

enum RequestStatus { idle, loading, success, failure }

/// Shared request + validation state for the form screens.
abstract class FormController extends ChangeNotifier {
  RequestStatus _status = RequestStatus.idle;
  RequestStatus get status => _status;
  bool get isLoading => _status == RequestStatus.loading;

  Failure? _failure;
  Failure? get failure => _failure;
  String? get errorMessage => _failure?.message;

  /// Set after the first submit attempt, so every field shows its errors.
  bool _submitted = false;
  bool get submitted => _submitted;

  bool _disposed = false;

  void markSubmitted() {
    if (_submitted) return;
    _submitted = true;
    notifyListeners();
  }

  void clearError() {
    if (_failure == null) return;
    _failure = null;
    if (_status == RequestStatus.failure) _status = RequestStatus.idle;
    notifyListeners();
  }

  /// Runs [task] with loading/error bookkeeping. Returns `null` (and does
  /// nothing) if a request is already in flight.
  @protected
  Future<Either<Failure, T>?> run<T>(Future<Either<Failure, T>> Function() task) async {
    if (isLoading) return null;
    _status = RequestStatus.loading;
    _failure = null;
    notifyListeners();

    final result = await task();
    result.fold(
      (f) {
        _status = RequestStatus.failure;
        _failure = f;
      },
      (_) => _status = RequestStatus.success,
    );
    notifyListeners();
    return result;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
