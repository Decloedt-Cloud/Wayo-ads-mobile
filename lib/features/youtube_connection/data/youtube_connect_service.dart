import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/config/youtube_oauth_config.dart';
import '../../../core/errors/auth_exceptions.dart';
import '../domain/youtube_channel.dart';
import 'youtube_remote.dart';

final youtubeConnectServiceProvider = Provider<YouTubeConnectService>((ref) {
  return YouTubeConnectService(ref.watch(youtubeRemoteProvider));
});

class YouTubeConnectService {
  YouTubeConnectService(this._remote);

  final YouTubeRemote _remote;

  Future<YouTubeConnectResult> connect({bool reconnect = false}) async {
    final init = await _remote.initiateConnect(reconnect: reconnect);

    try {
      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: init.authUrl,
        callbackUrlScheme: YouTubeOAuthConfig.callbackScheme,
      );

      final uri = Uri.parse(callbackUrl);
      final params = uri.queryParameters;

      final oauthError = params['error'];
      if (oauthError != null && oauthError.isNotEmpty) {
        throw ServerException(oauthError);
      }

      final success = params['success'];
      if (success == 'youtube_connected') {
        return YouTubeConnectResult(
          channelName: params['channelName'] ?? '',
          isReconnect: params['reconnect'] == '1',
        );
      }

      // Legacy: custom-scheme callback with code/state → mobile-complete.
      final code = params['code'];
      final state = params['state'];
      if (code != null &&
          code.isNotEmpty &&
          state != null &&
          state.isNotEmpty &&
          init.codeVerifier.isNotEmpty) {
        return _remote.completeMobileOAuth(
          code: code,
          state: state,
          codeVerifier: init.codeVerifier,
        );
      }

      throw const ServerException('invalid_state');
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        throw const ServerException('connection_cancelled');
      }
      throw ServerException(e.message ?? e.code);
    }
  }
}
