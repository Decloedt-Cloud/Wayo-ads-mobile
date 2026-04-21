import 'errors/auth_exceptions.dart';

/// Simple success/failure wrapper for repository calls.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(AuthException error) failure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final error) => failure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AuthException error;
}
