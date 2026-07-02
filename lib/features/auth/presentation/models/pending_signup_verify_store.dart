import 'signup_verify_payload.dart';

/// Holds signup OTP credentials across [GoRouter] refreshes (auth state updates).
SignupVerifyPayload? _pendingSignupVerifyPayload;

SignupVerifyPayload? readPendingSignupVerifyPayload() =>
    _pendingSignupVerifyPayload;

void stashPendingSignupVerifyPayload(SignupVerifyPayload payload) {
  _pendingSignupVerifyPayload = payload;
}

void clearPendingSignupVerifyPayload() {
  _pendingSignupVerifyPayload = null;
}
