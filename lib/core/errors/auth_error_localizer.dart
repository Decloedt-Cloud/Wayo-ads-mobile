import 'auth_exceptions.dart';
import '../../i18n/strings.g.dart';

/// Maps [AuthException] (and common API English phrases) to [Translations.errors].
String localizeAuthError(Object error, Translations t) {
  if (error is AuthException) {
    return switch (error) {
      InvalidCredentialsException(:final message) =>
        _fromServerMessage(message, t) ?? t.errors.invalid_credentials,
      NetworkException() => t.errors.network,
      ServerException(:final message) =>
        _fromServerMessage(message, t) ?? t.errors.server_generic,
      RateLimitedException(:final retryAfterSeconds) =>
        t.login.rate_limit_remaining(seconds: retryAfterSeconds),
      SessionInvalidException() => t.errors.session_invalid,
      EmailNotRegisteredException() => t.errors.email_not_found,
    };
  }
  return _fromServerMessage(error.toString(), t) ?? t.errors.unknown;
}

String? _fromServerMessage(String raw, Translations t) {
  final m = raw.toLowerCase().trim();

  // Throttling / rate limit (EN / FR / AR-ish keywords)
  if (m.contains('too many attempt') ||
      m.contains('try again in') ||
      m.contains('throttle') ||
      m.contains('rate limit') ||
      m.contains('trop de tentative') ||
      m.contains('trop de tentatives') ||
      m.contains('réessayez') ||
      m.contains('كثير من المحاولات')) {
    return t.errors.rate_limited;
  }
  if (m.contains('credential') ||
      m.contains('match our records') ||
      m.contains('incorrect') ||
      m.contains('identifiants') ||
      m.contains('incorrects') ||
      m.contains('بيانات') ||
      m.contains('غير صحيح') ||
      (m.contains('invalid') &&
          (m.contains('password') || m.contains('email')))) {
    return t.errors.invalid_credentials;
  }
  if (m.contains('no account') || m.contains('account found for this email')) {
    return t.errors.email_not_found;
  }
  if (m.contains('empty response') || m.contains('réponse vide')) {
    return t.errors.empty_response;
  }
  if (m.contains('login failed') || m.contains('échec de la connexion')) {
    return t.errors.login_failed;
  }
  if (m.contains('missing access token')) {
    return t.errors.session_invalid;
  }
  if (m.contains('apple sign-in is not configured') ||
      m.contains('sign in with apple is not enabled')) {
    return t.login.apple_server_not_configured;
  }
  if (m.contains('invalid apple token')) {
    return t.login.apple_failed;
  }
  return null;
}
