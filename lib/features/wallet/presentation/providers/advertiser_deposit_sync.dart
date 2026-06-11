import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../../invoices/presentation/providers/invoices_providers.dart';
import 'advertiser_wallet_providers.dart';

/// Keeps pending wallet checkout, balance, and advertiser invoices aligned.
void invalidateAdvertiserWalletDepositSync(WidgetRef ref) {
  ref.invalidate(advertiserWalletPageProvider);
  ref.invalidate(advertiserPendingDepositProvider);
  ref.invalidate(invoicesControllerProvider);
  ref.invalidate(dashboardStreamProvider);
}

/// When invoices reload, also refresh any in-progress wallet deposit checkout.
void syncAdvertiserPendingDepositFromInvoices(Ref ref) {
  final role = ref.read(currentWayoAdsAccountRoleProvider);
  if (role == WayoAdsAccountRole.advertiser ||
      role == WayoAdsAccountRole.superAdmin) {
    ref.invalidate(advertiserPendingDepositProvider);
  }
}
