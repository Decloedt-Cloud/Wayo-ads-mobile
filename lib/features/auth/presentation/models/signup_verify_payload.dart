/// Passed to [/signup/verify-otp] after email/password register.
final class SignupVerifyPayload {
  const SignupVerifyPayload({
    required this.email,
    required this.password,
    this.initialCodeSent = false,
    this.initialCooldownSeconds = 60,
    this.initialSendError,
  });

  final String email;
  final String password;

  /// Set when register flow already triggered (or attempted) verification email.
  final bool initialCodeSent;
  final int initialCooldownSeconds;
  final String? initialSendError;
}
