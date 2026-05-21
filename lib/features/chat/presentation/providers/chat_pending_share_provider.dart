import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Files shared into Wayo (Android/iOS share sheet) until a thread consumes them.
final chatPendingShareProvider = StateProvider<List<SharedMediaFile>>(
  (ref) => const [],
);
