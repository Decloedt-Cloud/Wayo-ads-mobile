import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// iOS Sign in with Apple — yields an identity token for Auth_Wayo (`POST …/apple`).
final class AppleSignInResult {
  const AppleSignInResult({
    required this.identityToken,
    required this.rawNonce,
    this.authorizationCode,
    this.userIdentifier,
  });

  final String identityToken;
  final String rawNonce;
  final String? authorizationCode;
  final String? userIdentifier;
}

abstract final class AppleSignInFacade {
  AppleSignInFacade._();

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Returns `null` if Apple did not return an identity token (e.g. dismissed sheet).
  static Future<AppleSignInResult?> signInOnIos() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }
    final isAvail = await SignInWithApple.isAvailable();
    if (!isAvail) {
      return null;
    }

    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    }

    final token = credential.identityToken;
    if (token == null || token.isEmpty) {
      return null;
    }

    return AppleSignInResult(
      identityToken: token,
      rawNonce: rawNonce,
      authorizationCode: credential.authorizationCode,
      userIdentifier: credential.userIdentifier,
    );
  }

  static bool isUserCanceled(Object e) {
    if (e is SignInWithAppleAuthorizationException) {
      return e.code == AuthorizationErrorCode.canceled;
    }
    final s = e.toString().toLowerCase();
    return s.contains('canceled') || s.contains('cancelled');
  }
}
