class RegisterFieldAvailability {
  const RegisterFieldAvailability({
    required this.available,
    this.reason,
    this.message,
  });

  final bool available;
  final String? reason;
  final String? message;

  factory RegisterFieldAvailability.fromJson(Map<String, dynamic> json) {
    return RegisterFieldAvailability(
      available: json['available'] == true,
      reason: json['reason'] as String?,
      message: json['message'] as String?,
    );
  }
}

enum RegisterFieldCheckState {
  unknown,
  checking,
  ok,
  taken,
  disposable,
  invalid,
  error,
}

final class RegisterFieldCheck {
  const RegisterFieldCheck({
    this.state = RegisterFieldCheckState.unknown,
    this.message,
  });

  final RegisterFieldCheckState state;
  final String? message;

  bool get blocksSubmit =>
      state == RegisterFieldCheckState.unknown ||
      state == RegisterFieldCheckState.checking ||
      state == RegisterFieldCheckState.taken ||
      state == RegisterFieldCheckState.disposable ||
      state == RegisterFieldCheckState.error;
}
