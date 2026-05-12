import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When false, [CampaignsExplorerToolbar] hides search + filters to save space.
final campaignsExplorerToolbarExpandedProvider = StateProvider<bool>(
  (ref) => true,
);
