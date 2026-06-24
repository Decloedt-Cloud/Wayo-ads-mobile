import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/auth/data/models/app_user.dart';
import '../features/auth/domain/auth_notifier.dart';
import '../i18n/strings.g.dart';
import '../shared/widgets/animated_logout_icon.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final auth = ref.watch(authNotifierProvider);
    final AppUser? user = auth.maybeWhen(
      data: (s) => switch (s) {
        AuthAuthenticated(:final user) => user,
        _ => null,
      },
      orElse: () => null,
    );

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.home.title),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
            icon: AnimatedLogoutIcon(
              size: 20,
              color: theme.colorScheme.primary,
            ),
            label: Text(t.home.logout),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(t.home.session_title, style: AppTextStyles.pageTitle(context)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: user.avatar != null && user.avatar!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.avatar!,
                        width: 40,
                        height: 40,
                        memCacheWidth: 80,
                        memCacheHeight: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Text(
                          (user.name ?? user.email).isNotEmpty
                              ? (user.name ?? user.email)[0].toUpperCase()
                              : '?',
                        ),
                      ),
                    )
                  : (user.name != null && user.name!.isNotEmpty
                        ? Text(user.name![0].toUpperCase())
                        : const Icon(Icons.person)),
            ),
            title: Text(user.name ?? t.home.user_fallback),
            subtitle: Text(user.email),
          ),
          const SizedBox(height: 24),
          Text(
            t.home.session_hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => context.push('/privacy'),
            icon: const Icon(Icons.privacy_tip_outlined, size: 20),
            label: Text(t.login.privacy),
          ),
        ],
      ),
    );
  }
}
