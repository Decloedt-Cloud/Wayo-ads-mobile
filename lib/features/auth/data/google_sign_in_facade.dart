import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/auth_runtime_config.dart';

/// Single [GoogleSignIn] per server client id — avoids repeated Pigeon `init` on Android.
/// Call [signInForIdToken] after the UI is mounted; waits for a frame before touching the plugin.
final class GoogleSignInFacade {
  GoogleSignInFacade._();

  static GoogleSignIn? _client;
  static String? _serverClientId;

  static GoogleSignIn _ensureClient(String serverClientId) {
    if (_client != null && _serverClientId == serverClientId) {
      return _client!;
    }
    _serverClientId = serverClientId;
    _client = _buildClient(serverClientId);
    return _client!;
  }

  /// Clears cached client (e.g. after logout) so the next sign-in re-inits cleanly.
  static void reset() {
    _client = null;
    _serverClientId = null;
  }

  /// Clears cached Google account so the next [signIn] shows the account picker.
  ///
  /// [disconnect] is Android-only — on iOS it can abort the process when no
  /// prior Google session exists. [signOut] is enough to show the account picker.
  static Future<void> _clearGoogleSession(GoogleSignIn google) async {
    try {
      await google.signOut();
    } catch (_) {}
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      if (await google.isSignedIn()) {
        await google.disconnect();
      }
    } catch (_) {}
  }

  /// Clears the Google session on device so the next sign-in shows account picker.
  static Future<void> signOutFromGoogle() async {
    final cid =
        _serverClientId ?? AuthRuntimeConfig.instance.googleServerClientId;
    if (cid.isEmpty) {
      reset();
      return;
    }
    try {
      final client = _client ?? _buildClient(cid);
      await _clearGoogleSession(client);
    } catch (_) {
      // Non-fatal: user may not have signed in with Google this session.
    } finally {
      reset();
    }
  }

  static GoogleSignIn _buildClient(String serverClientId) => GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: serverClientId,
      );

  static bool _isChannelError(Object e) {
    if (e is PlatformException) {
      if (e.code == 'channel-error') {
        return true;
      }
    }
    final s = e.toString();
    return s.contains('pigeon') ||
        s.contains('channel') ||
        s.contains('Unable to establish connection on channel');
  }

  static bool looksLikeStaleChannel(Object e) => _isChannelError(e);

  /// [com.google.android.gms.common.api.ApiException]: `10` = [DEVELOPER_ERROR]
  /// (package name + SHA-1 must be registered for an **Android** OAuth client in the
  /// same Google Cloud project as the Web client id used in [serverClientId]).
  static bool isAndroidDeveloperConfigError(Object e) {
    final combined = e is PlatformException
        ? '${e.code} ${e.message ?? ''} ${e.details ?? ''}'
        : e.toString();
    return combined.contains('ApiException: 10');
  }

  /// Returns Google [id_token] for the signed-in account, or `null` if cancelled / no token.
  static Future<String?> signInForIdToken(String serverClientId) async {
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 32));

    Future<String?> attempt() async {
      final google = _ensureClient(serverClientId);
      // signIn() reuses [currentUser] unless the session was cleared first.
      await _clearGoogleSession(google);
      final account = await google.signIn();
      if (account == null) {
        return null;
      }
      final auth = await account.authentication;
      final id = auth.idToken;
      if (id == null || id.isEmpty) {
        return null;
      }
      return id;
    }

    try {
      return await attempt();
    } on PlatformException catch (e) {
      if (_isChannelError(e)) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        reset();
        return await attempt();
      }
      rethrow;
    } catch (e) {
      if (_isChannelError(e)) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        reset();
        return await attempt();
      }
      rethrow;
    }
  }
}
