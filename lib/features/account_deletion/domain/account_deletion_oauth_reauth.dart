import '../../auth/data/apple_sign_in_facade.dart';

/// Builds the `reauth` body for [POST /api/user/delete-account] (Bearer mobile).
///
/// Wayo-ads reads camelCase (`idToken`, `identityToken`, …). Snake_case aliases are
/// included for forward compatibility with Auth_Wayo-style parsers.
Map<String, dynamic> buildGoogleDeletionReauth(String idToken) {
  final token = idToken.trim();
  return {
    'provider': 'google',
    'idToken': token,
    'id_token': token,
  };
}

Map<String, dynamic> buildAppleDeletionReauth(AppleSignInResult cred) {
  final identity = cred.identityToken.trim();
  final nonce = cred.rawNonce.trim();
  final authCode = cred.authorizationCode?.trim();
  final appleUserId = cred.userIdentifier?.trim();

  return {
    'provider': 'apple',
    'identityToken': identity,
    'identity_token': identity,
    'id_token': identity,
    'nonce': nonce,
    if (authCode != null && authCode.isNotEmpty) ...{
      'authorizationCode': authCode,
      'authorization_code': authCode,
    },
    if (appleUserId != null && appleUserId.isNotEmpty) ...{
      'appleUserId': appleUserId,
      'apple_user_id': appleUserId,
    },
  };
}
