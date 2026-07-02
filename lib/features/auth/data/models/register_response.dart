import 'app_user.dart';
import 'auth_response.dart';

class RegisterResponse {
  const RegisterResponse({
    required this.user,
    this.auth,
  });

  final AppUser user;

  /// Present when email is auto-verified (trusted `app_key`) — same as login.
  final AuthResponse? auth;

  /// Web parity: email/password signup always requires OTP before first login.
  /// Ignores `app_key` auto-verify flags on the register payload.
  bool get requiresEmailVerificationBeforeUse => true;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> payload = json;
    if (json['data'] is Map<String, dynamic>) {
      payload = Map<String, dynamic>.from(json['data'] as Map<String, dynamic>);
    }

    final userRaw = payload['user'];
    if (userRaw is! Map<String, dynamic>) {
      throw FormatException('RegisterResponse: missing user object');
    }

    final token = payload['access_token'];
    AuthResponse? auth;
    if (token is String && token.isNotEmpty) {
      auth = AuthResponse.fromJson(json);
    }

    return RegisterResponse(
      user: AppUser.fromJson(Map<String, dynamic>.from(userRaw)),
      auth: auth,
    );
  }
}
