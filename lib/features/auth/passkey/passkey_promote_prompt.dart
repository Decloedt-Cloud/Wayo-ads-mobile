import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import 'passkey_exceptions.dart';
import 'passkey_feature_flags.dart';
import 'passkey_missing_sheet.dart';
import 'passkey_service.dart';

/// Non-blocking prompt after traditional login (email / Google / Apple).
abstract final class PasskeyPromotePrompt {
  static const _dismissedKey = 'passkey.promote.dismissed_v1';

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_dismissedKey) == true) return;
      final flags = await PasskeyFeatureFlags.resolve();
      if (!flags.registration) return;
      final avail = await ref.read(passkeyServiceProvider).availability();
      if (!avail.canRegister) return;
      final existing = await ref.read(passkeyServiceProvider).listPasskeys();
      if (existing.isNotEmpty) return;
      if (!context.mounted) return;

      final t = context.t;
      final scheme = Theme.of(context).colorScheme;
      final choice = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.app_settings.passkeys_promote_title,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.app_settings.passkeys_promote_body,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'create'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(t.app_settings.passkeys_promote_create),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'later'),
                    child: Text(t.app_settings.passkeys_promote_later),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (choice == 'later' || choice == null) {
        await prefs.setBool(_dismissedKey, true);
        return;
      }
      if (choice == 'create') {
        await prefs.setBool(_dismissedKey, true);
        try {
          await ref.read(passkeyServiceProvider).createPasskey(
                friendlyName: t.app_settings.passkeys_default_name,
              );
          if (!context.mounted) return;
          await showPasskeyCreatedSheet(
            context,
            title: t.login.passkey_created_title,
            body: t.login.passkey_created_body,
            actionLabel: t.login.passkey_created_action,
          );
        } on PasskeyCancelled {
          // Quiet
        } catch (_) {
          if (context.mounted) {
            WayoToast.error(context, t.app_settings.passkeys_error);
          }
        }
      }
    } catch (_) {
      // Never block post-login navigation.
    }
  }
}
