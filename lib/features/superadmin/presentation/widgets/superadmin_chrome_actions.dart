import 'package:flutter/material.dart';

import '../../../dashboard/presentation/widgets/internal_notification_bell.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';

/// Top-right chrome for superadmin screens (theme + optional notifications).
class SuperadminChromeActions extends StatelessWidget {
  const SuperadminChromeActions({
    super.key,
    this.showNotifications = false,
    this.trailingPadding = 0,
  });

  final bool showNotifications;
  final double trailingPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: trailingPadding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showNotifications) ...[
            const InternalNotificationBell(),
            const SizedBox(width: 8),
          ],
          const ThemeToggleButton(),
        ],
      ),
    );
  }
}
