import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/data/models/app_user.dart';
import '../auth/presentation/providers/current_account_providers.dart';

/// Builds a shell tab only when [currentAppUserProvider] is non-null.
///
/// During logout, auth becomes [AuthUnauthenticated] a frame or two before GoRouter
/// leaves the shell; without this gate, role defaults to `unknown` and UIs that
/// treat only `creator` specially fall through to the **advertiser** branch (flash).
typedef ShellTabSignedInBuilder =
    Widget Function(BuildContext context, WidgetRef ref, AppUser user);

class ShellTabSignedInGate extends ConsumerWidget {
  const ShellTabSignedInGate({super.key, required this.builder});

  final ShellTabSignedInBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider);
    if (user == null) {
      return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: const SizedBox.expand(),
      );
    }
    return builder(context, ref, user);
  }
}
