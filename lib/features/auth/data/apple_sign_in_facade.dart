import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/config/auth_runtime_config.dart';

/// Sign in with Apple — yields an identity token for Auth_Wayo (`POST …/apple`).
///
/// - **iOS:** native ASAuthorization
/// - **Android:** Apple web OAuth via Chrome Custom Tabs (`WebAuthenticationOptions`)
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

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

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

  /// Native iOS Sign in with Apple.
  ///
  /// Prefer [signIn] which also supports Android.
  static Future<AppleSignInResult?> signInOnIos() => signIn();

  /// Returns `null` if Apple did not return an identity token (e.g. dismissed).
  static Future<AppleSignInResult?> signIn() async {
    if (!isSupportedPlatform) {
      return null;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final isAvail = await SignInWithApple.isAvailable();
      if (!isAvail) {
        return null;
      }
    }

    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    WebAuthenticationOptions? webOptions;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final clientId = AuthRuntimeConfig.instance.appleWebClientId.trim();
      final redirect = AuthRuntimeConfig.instance.appleAndroidRedirectUri.trim();
      if (clientId.isEmpty || redirect.isEmpty) {
        return null;
      }
      webOptions = WebAuthenticationOptions(
        clientId: clientId,
        redirectUri: Uri.parse(redirect),
      );
    }

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        webAuthenticationOptions: webOptions,
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
