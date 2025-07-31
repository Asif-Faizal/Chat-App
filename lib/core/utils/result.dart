import '../error/failures.dart';

/// A Result type that represents either success (Right) or failure (Left)
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}

/// Extension methods for Result to make it easier to work with
extension ResultExtension<T> on Result<T> {
  /// Returns true if the result is a success
  bool get isSuccess => this is Success<T>;
  
  /// Returns true if the result is an error
  bool get isError => this is Error<T>;
  
  /// Returns the data if success, null otherwise
  T? get data => isSuccess ? (this as Success<T>).data : null;
  
  /// Returns the failure if error, null otherwise
  Failure? get failure => isError ? (this as Error<T>).failure : null;
  
  /// Transforms the success value using the provided function
  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Success<T>(data: final data) => Success(transform(data)),
      Error<T>(failure: final failure) => Error(failure),
    };
  }
  
  /// Executes the appropriate callback based on the result
  R fold<R>(
    R Function(Failure failure) onError,
    R Function(T data) onSuccess,
  ) {
    return switch (this) {
      Success<T>(data: final data) => onSuccess(data),
      Error<T>(failure: final failure) => onError(failure),
    };
  }
}