import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/password_reset_remote_datasource.dart';

sealed class ForgotPasswordState {
  const ForgotPasswordState();
}

final class FpIdle extends ForgotPasswordState {
  const FpIdle();
}

final class FpLoading extends ForgotPasswordState {
  const FpLoading();
}

final class FpOtpSent extends ForgotPasswordState {
  const FpOtpSent(this.email, this.ttlSeconds);
  final String email;
  final int ttlSeconds;
}

final class FpOtpVerified extends ForgotPasswordState {
  const FpOtpVerified(this.resetToken, this.expiresIn);
  final String resetToken;
  final int expiresIn;
}

final class FpSuccess extends ForgotPasswordState {
  const FpSuccess();
}

final class FpError extends ForgotPasswordState {
  const FpError(this.error);
  final Object error;
}

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this._ds) : super(const FpIdle());

  final PasswordResetRemoteDataSource _ds;

  void reset() => state = const FpIdle();

  /// Clears [FpError] (e.g. after rate-limit countdown).
  void clearError() {
    if (state is FpError) {
      state = const FpIdle();
    }
  }

  Future<void> requestOtp(String email) async {
    state = const FpLoading();
    final result = await _ds.sendOtp(email);
    result.when(
      success: (ttl) {
        state = FpOtpSent(email, ttl);
      },
      failure: (e) => state = FpError(e),
    );
  }

  Future<void> verifyOtp(String email, String otp) async {
    state = const FpLoading();
    final result = await _ds.verifyOtp(email: email, otp: otp);
    result.when(
      success: (data) {
        state = FpOtpVerified(data.resetToken, data.expiresIn);
      },
      failure: (e) => state = FpError(e),
    );
  }

  Future<void> resetPassword({
    required String resetToken,
    required String password,
  }) async {
    state = const FpLoading();
    final result = await _ds.resetPassword(
      resetToken: resetToken,
      password: password,
    );
    result.when(
      success: (_) => state = const FpSuccess(),
      failure: (e) => state = FpError(e),
    );
  }
}

/// Not autoDispose: survives [GoRouter] pushes between forgot → OTP → new password.
final forgotPasswordControllerProvider =
    StateNotifierProvider<ForgotPasswordController, ForgotPasswordState>((ref) {
  return ForgotPasswordController(ref.watch(passwordResetRemoteDataSourceProvider));
});
