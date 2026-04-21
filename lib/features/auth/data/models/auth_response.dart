import 'app_user.dart';

class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final AppUser user;

  /// Parses Auth_Wayo JSON: either a flat OAuth-style map or the Laravel API envelope
  /// `{ "success": true, "data": { "user", "access_token", ... } }`.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> payload = json;
    if (json['data'] is Map<String, dynamic>) {
      payload = Map<String, dynamic>.from(json['data'] as Map<String, dynamic>);
    }

    final userRaw = payload['user'];
    if (userRaw is! Map<String, dynamic>) {
      throw FormatException('AuthResponse: missing user object');
    }

    final refresh = payload['refresh_token'];
    final refreshStr = refresh is String ? refresh : '';

    return AuthResponse(
      accessToken: payload['access_token'] as String? ?? '',
      refreshToken: refreshStr,
      tokenType: payload['token_type'] as String? ?? 'Bearer',
      expiresIn: _resolveExpiresIn(payload),
      user: AppUser.fromJson(userRaw),
    );
  }

  static int _resolveExpiresIn(Map<String, dynamic> payload) {
    final fromField = (payload['expires_in'] as num?)?.toInt();
    if (fromField != null && fromField > 0) {
      return fromField;
    }
    final at = payload['expires_at'];
    if (at is String) {
      final dt = DateTime.tryParse(at);
      if (dt != null) {
        final secs = dt.difference(DateTime.now()).inSeconds;
        if (secs > 0) {
          return secs;
        }
      }
    }
    // // TODO(dev): align with PASSPORT_TOKEN_EXPIRATION when server omits both fields.
    return 3600;
  }
}
