import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    _client = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: serverClientId,
    );
    return _client!;
  }

  /// Clears cached client (e.g. after logout) so the next sign-in re-inits cleanly.
  static void reset() {
    _client = null;
    _serverClientId = null;
  }

  /// Call after app logout so the next "Continue with Google" shows the account picker again.
  static Future<void> signOutFromGoogle() async {
    try {
      if (_client != null) {
        await _client!.signOut();
      }
    } catch (_) {
      // Non-fatal: account may not have used Google this session.
    } finally {
      reset();
    }
  }

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
