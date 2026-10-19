// File: lib/core/errors/result.dart

// Base class for all error types in the app
abstract class Failure {
  final String message;
  final String? code;

  Failure({required this.message, this.code});
}

// Error returned from the API (Server), e.g. 404, 500, or 422
class ServerFailure extends Failure {
  ServerFailure({required super.message, super.code});
}

// Result class to avoid try-catch in the UI layer
class Result<T> {
  final Failure? _failure;
  final T? _data;
  final bool _isSuccess;

  // Create a Result when the data is returned successfully
  Result.success(this._data)
      : _isSuccess = true,
        _failure = null;

  // Create a Result when there is an error or failure
  Result.failure(this._failure)
      : _isSuccess = false,
        _data = null;

  // fold forces the UI to always handle both cases (success and failure)
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T data) onSuccess,
  ) {
    if (_isSuccess) {
      return onSuccess(_data as T);
    } else {
      return onFailure(_failure!);
    }
  }
}
