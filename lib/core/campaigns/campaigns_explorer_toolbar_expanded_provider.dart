import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When false, [CampaignsExplorerToolbar] hides search + filters (collapsed by default).
final campaignsExplorerToolbarExpandedProvider = StateProvider<bool>(
  (ref) => false,
);
