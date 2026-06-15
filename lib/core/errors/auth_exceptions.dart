sealed class AuthException implements Exception {
  const AuthException();
}

final class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException([
    this.message = 'These credentials do not match our records.',
  ]);
  final String message;
  @override
  String toString() => message;
}

final class NetworkException extends AuthException {
  const NetworkException([this.message = 'Network error']);
  final String message;
  @override
  String toString() => message;
}

final class ServerException extends AuthException {
  const ServerException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

/// HTTP 429 — login throttled. [retryAfterSeconds] comes from JSON `retry_after` or `Retry-After`.
final class RateLimitedException extends AuthException {
  const RateLimitedException({required this.retryAfterSeconds});
  final int retryAfterSeconds;
  @override
  String toString() => 'RateLimitedException($retryAfterSeconds)';
}

/// Refresh rejected (e.g. 401) — session must end.
final class SessionInvalidException extends AuthException {
  const SessionInvalidException();
  @override
  String toString() => 'SessionInvalidException';
}

/// Password reset: no user for this email (HTTP 404).
final class EmailNotRegisteredException extends AuthException {
  const EmailNotRegisteredException([
    this.message = 'No account found for this email.',
  ]);
  final String message;
  @override
  String toString() => message;
}

/// HTTP 409 — active Wayo Ads web session blocks mobile login until web logout.
final class WebSessionActiveException extends AuthException {
  const WebSessionActiveException({
    this.message =
        'You are already signed in on the Wayo Ads website. Sign out from the web before signing in on the app.',
    this.logoutUrl,
  });
  final String message;
  final String? logoutUrl;
  @override
  String toString() => message;
}
