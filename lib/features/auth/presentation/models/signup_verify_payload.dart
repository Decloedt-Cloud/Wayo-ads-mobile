/// Passed to [/signup/verify-otp] when register succeeds without tokens (rare).
final class SignupVerifyPayload {
  const SignupVerifyPayload({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}
