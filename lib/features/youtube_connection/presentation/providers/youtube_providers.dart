import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/youtube_remote.dart';
import '../../domain/youtube_channel.dart';

final youtubeChannelStatusProvider =
    FutureProvider.autoDispose<YouTubeChannelResponse>((ref) async {
      return ref.watch(youtubeRemoteProvider).fetchChannelStatus();
    });
