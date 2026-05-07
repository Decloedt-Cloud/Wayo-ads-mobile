import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart' as pr;

import '../config/auth_runtime_config.dart';
import '../network/api_endpoints.dart';
import '../storage/secure_storage.dart';
import 'realtime_channels.dart';
import 'realtime_signal.dart';

/// Laravel Reverb client — balance / campaigns / notifications push invalidation.
///
/// Uses [pusher_reverb_flutter] (custom host) instead of cluster-only clients.
final class WayoReverbRealtime {
  WayoReverbRealtime(this._storage);

  final SecureStorageService _storage;

  final StreamController<RealtimeSignal> _signals =
      StreamController<RealtimeSignal>.broadcast();

  Stream<RealtimeSignal> get signals => _signals.stream;

  final List<StreamSubscription<pr.ChannelEvent>> _subs = [];

  int? _connectedUserId;

  /// Subscribes to advertiser + user private channels for [userId].
  ///
  /// Never throws: failures/timeouts clear state so the UI can proceed without realtime.
  Future<void> connectForUser(int userId) async {
    try {
      await _connectForUserImpl(userId);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[WayoReverb] connectForUser suppressed: $e\n$st');
      }
      try {
        await disconnect();
      } catch (_) {}
    }
  }

  Future<void> _connectForUserImpl(int userId) async {
    final runtime = AuthRuntimeConfig.instance;
    if (!runtime.reverbConfigured) {
      return;
    }
    final host = runtime.reverbHost.trim();
    final key = runtime.reverbKey.trim();
    if (host.isEmpty || key.isEmpty) {
      return;
    }
    final base = runtime.resolvedWayoAdsBaseUrl;
    if (base.isEmpty) {
      return;
    }
    if (_connectedUserId == userId) {
      try {
        final existing = pr.ReverbClient.instance();
        if (existing.connectionState == pr.ConnectionState.connected) {
          return;
        }
      } catch (_) {}
    }
    await disconnect();
    _connectedUserId = userId;

    final authUrl = AuthRuntimeConfig.instance.wayoAdsAbsoluteUrl(
      ApiEndpoints.broadcastingAuth,
    );
    final port = int.tryParse(runtime.reverbPort) ?? 443;
    final useTls = runtime.reverbScheme.toLowerCase() == 'https';

    pr.ReverbClient.instance(
      host: host,
      port: port,
      appKey: key,
      authorizer: _authorizer,
      authEndpoint: authUrl,
      useTLS: useTls,
      onError: (e) {
        if (kDebugMode) {
          debugPrint('[WayoReverb] error: $e');
        }
      },
    );

    await pr.ReverbClient.instance().connect().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Reverb.connect'),
        );

    final adv = pr.ReverbClient.instance().subscribeToPrivateChannel(
      RealtimeChannels.advertiser(userId),
    );
    final creator = pr.ReverbClient.instance().subscribeToPrivateChannel(
      RealtimeChannels.creator(userId),
    );
    final usr = pr.ReverbClient.instance().subscribeToPrivateChannel(
      RealtimeChannels.user(userId),
    );

    void forward(pr.ChannelEvent e) {
      if (e.eventName.startsWith('pusher:')) {
        return;
      }
      _signals.add(
        RealtimeSignal(
          name: e.eventName,
          channelName: e.channelName,
          raw: e.data,
        ),
      );
    }

    _subs
      ..add(adv.stream.listen(forward))
      ..add(creator.stream.listen(forward))
      ..add(usr.stream.listen(forward));
  }

  Future<Map<String, String>> _authorizer(
    String channelName,
    String socketId,
  ) async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return const {};
    }
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  /// Stops websocket subscriptions (e.g. on logout).
  ///
  /// Best-effort: does not throw.
  Future<void> disconnect() async {
    try {
      for (final s in _subs) {
        await s.cancel();
      }
      _subs.clear();
      _connectedUserId = null;
      // ignore: invalid_use_of_visible_for_testing_member
      pr.ReverbClient.resetInstance();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await disconnect();
    } catch (_) {}
  }
}
