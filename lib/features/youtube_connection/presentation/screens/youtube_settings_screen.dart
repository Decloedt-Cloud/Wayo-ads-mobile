import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/youtube_channel.dart';
import '../providers/youtube_providers.dart';
import '../youtube_actions.dart';

class YouTubeSettingsScreen extends ConsumerWidget {
  const YouTubeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.youtube;
    final statusAsync = ref.watch(youtubeChannelStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(t.title, style: AppTextStyles.headlineMedium(context)),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () async {
          ref.invalidate(youtubeChannelStatusProvider);
          await ref.read(youtubeChannelStatusProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            statusAsync.when(
              data: (response) {
                if (response.needsReconnect) {
                  return _ReconnectPanel(channel: response.channel);
                }
                if (response.isConnected && response.channel != null) {
                  return _ConnectedPanel(channel: response.channel!);
                }
                return const _NotConnectedPanel();
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const _NotConnectedPanel(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotConnectedPanel extends ConsumerWidget {
  const _NotConnectedPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.youtube;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.not_connected, style: AppTextStyles.headlineMedium(context)),
        const SizedBox(height: 8),
        Text(
          t.connect_subtitle,
          style: AppTextStyles.bodyLarge(
            context,
          ).copyWith(color: AppColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => runYouTubeConnect(context, ref),
          icon: const Icon(Icons.link_rounded),
          label: Text(t.connect),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ReconnectPanel extends ConsumerWidget {
  const _ReconnectPanel({required this.channel});

  final YouTubeChannel? channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.youtube;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (channel != null) ...[
          _ChannelSummary(channel: channel!),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            t.reconnect_subtitle,
            style: const TextStyle(color: Colors.orange, fontSize: 13),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => runYouTubeConnect(context, ref, reconnect: true),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(t.reconnect),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ConnectedPanel extends ConsumerWidget {
  const _ConnectedPanel({required this.channel});

  final YouTubeChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.youtube;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChannelSummary(channel: channel),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => runYouTubeRefresh(context, ref),
          icon: const Icon(Icons.sync_rounded),
          label: Text(t.refresh),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => runYouTubeDisconnect(context, ref),
          child: Text(
            t.disconnect,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      ],
    );
  }
}

class _ChannelSummary extends StatelessWidget {
  const _ChannelSummary({required this.channel});

  final YouTubeChannel channel;

  @override
  Widget build(BuildContext context) {
    final t = context.t.youtube;
    final avatar = channel.channelAvatar;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.surfaceElevatedOf(context),
          backgroundImage: avatar != null && avatar.isNotEmpty
              ? CachedNetworkImageProvider(avatar)
              : null,
          child: avatar == null || avatar.isEmpty
              ? const Icon(Icons.play_circle_fill, color: Colors.red)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                channel.channelName,
                style: AppTextStyles.headlineMedium(context),
              ),
              if (channel.channelHandle != null &&
                  channel.channelHandle!.isNotEmpty)
                Text(
                  channel.channelHandle!,
                  style: AppTextStyles.caption(context),
                ),
              if (channel.subscriberCount != null)
                Text(
                  t.subscribers(count: channel.subscriberCount!),
                  style: AppTextStyles.caption(context),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
