/// Thrown when refresh fails and the user must sign in again.
class SessionExpiredException implements Exception {
  const SessionExpiredException([this.message = 'Session expired']);
  final String message;
  @override
  String toString() => message;
}
