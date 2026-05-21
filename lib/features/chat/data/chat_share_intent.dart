import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Android/iOS share-target → callback (e.g. Riverpod pending queue).
class ChatShareIntent {
  ChatShareIntent._();

  static StreamSubscription<List<SharedMediaFile>>? _sub;
  static bool _started = false;

  /// Call once from [ChatInboxScreen] so shares are captured before a thread opens.
  static void bind(void Function(List<SharedMediaFile> files) onFiles) {
    if (kIsWeb || _started) return;
    _started = true;

    void dispatch(List<SharedMediaFile> files) {
      if (files.isEmpty) return;
      onFiles(files);
    }

    _sub?.cancel();
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(dispatch);
    unawaited(
      ReceiveSharingIntent.instance.getInitialMedia().then(dispatch),
    );
  }

  static Future<void> reset() async {
    if (kIsWeb) return;
    await ReceiveSharingIntent.instance.reset();
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }
}
