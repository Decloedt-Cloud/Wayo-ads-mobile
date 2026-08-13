/// Typed passkey / WebAuthn errors — never leak raw platform messages to users.
sealed class PasskeyException implements Exception {
  const PasskeyException(this.code, [this.message]);
  final String code;
  final String? message;

  @override
  String toString() => 'PasskeyException($code)';
}

final class PasskeyCancelled extends PasskeyException {
  const PasskeyCancelled() : super('cancelled');
}

final class PasskeyUnavailable extends PasskeyException {
  const PasskeyUnavailable([String? message]) : super('unavailable', message);
}

/// No discoverable credential on this device (NoCredentialException).
final class PasskeyNotFound extends PasskeyException {
  const PasskeyNotFound() : super('not_found');
}

final class PasskeyInterrupted extends PasskeyException {
  const PasskeyInterrupted([String? message]) : super('interrupted', message);
}

final class PasskeyConfigurationError extends PasskeyException {
  const PasskeyConfigurationError([String? message])
      : super('configuration', message);
}

final class PasskeyNetworkError extends PasskeyException {
  const PasskeyNetworkError([String? message]) : super('network', message);
}

final class PasskeyServerRejected extends PasskeyException {
  const PasskeyServerRejected([String? message])
      : super('server_rejected', message);
}

final class PasskeyLastCredential extends PasskeyException {
  const PasskeyLastCredential([String? message])
      : super('last_credential', message);
}

final class PasskeyLimitReached extends PasskeyException {
  const PasskeyLimitReached([String? message]) : super('limit_reached', message);
}

final class PasskeyExpiredChallenge extends PasskeyException {
  const PasskeyExpiredChallenge() : super('expired_challenge');
}

final class PasskeyUnknownError extends PasskeyException {
  const PasskeyUnknownError([String? message]) : super('unknown', message);
}

/// Provider/OS refused create because a matching passkey already exists for this RP.
final class PasskeyAlreadyExists extends PasskeyException {
  const PasskeyAlreadyExists([String? message])
      : super('already_exists', message);
}
