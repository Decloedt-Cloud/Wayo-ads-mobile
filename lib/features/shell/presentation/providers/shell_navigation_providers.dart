import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active bottom-nav branch from [StatefulNavigationShell.currentIndex].
///
/// 0 = dashboard, 1 = campaigns, 2 = wallet, 3 = invoices, 4 = chat.
/// Used by background refresh logic to avoid invalidating off-screen tabs.
final shellCurrentIndexProvider = StateProvider<int>((ref) => 0);
