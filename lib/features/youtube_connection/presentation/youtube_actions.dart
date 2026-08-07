import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../../../core/ui/wayo_toast.dart';
import '../../../i18n/strings.g.dart';
import '../data/youtube_connect_service.dart';
import '../data/youtube_remote.dart';
import 'providers/youtube_providers.dart';

Future<void> runYouTubeConnect(
  BuildContext context,
  WidgetRef ref, {
  bool reconnect = false,
}) async {
  final t = context.t.youtube;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  try {
    final result = await ref
        .read(youtubeConnectServiceProvider)
        .connect(reconnect: reconnect);
    ref.invalidate(youtubeChannelStatusProvider);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    final message = result.isReconnect || reconnect
        ? t.reconnect_success(channelName: result.channelName)
        : t.connect_success(channelName: result.channelName);
    WayoToast.success(context, message);
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    WayoToast.error(context, mapYouTubeError(context.t, e));
  }
}

Future<void> runYouTubeDisconnect(BuildContext context, WidgetRef ref) async {
  final t = context.t.youtube;
  final confirmed = await showWayoConfirmDialog(
    context: context,
    title: t.disconnect,
    message: t.disconnect_confirm,
    cancelLabel: t.cancel,
    confirmLabel: t.disconnect,
    tone: WayoDialogTone.destructive,
  );

  if (!confirmed || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  try {
    await ref.read(youtubeRemoteProvider).disconnect();
    ref.invalidate(youtubeChannelStatusProvider);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    WayoToast.success(context, t.disconnect_success);
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    WayoToast.error(context, t.error_generic);
  }
}

Future<void> runYouTubeRefresh(BuildContext context, WidgetRef ref) async {
  final t = context.t.youtube;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  try {
    await ref.read(youtubeRemoteProvider).refreshChannel();
    ref.invalidate(youtubeChannelStatusProvider);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    WayoToast.success(context, t.refresh_success);
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    WayoToast.error(context, t.error_generic);
  }
}

String mapYouTubeError(Translations t, Object error) {
  final code = switch (error) {
    ServerException(:final message) => message,
    NetworkException(:final message) => message,
    _ => error.toString(),
  };

  final yt = t.youtube;
  return switch (code) {
    'oauth_denied' => yt.error_oauth_denied,
    'invalid_state' => yt.error_invalid_state,
    'missing_pkce' => yt.error_missing_pkce,
    'token_exchange_failed' => yt.error_token_exchange,
    'stats_fetch_failed' => yt.error_stats_fetch,
    'channel_already_connected' => yt.error_channel_taken,
    'connection_failed' => yt.error_generic,
    'connection_cancelled' => yt.error_cancelled,
    'YouTube channel already connected' => yt.error_already_connected,
    'Already connected' => yt.error_already_connected,
    _ => code.isNotEmpty ? code : yt.error_generic,
  };
}
