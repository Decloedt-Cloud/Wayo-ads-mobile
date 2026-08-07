import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../domain/creator_business_profile.dart';
import '../providers/creator_wallet_providers.dart';
import 'business_info_screen.dart';

/// GoRouter host for `/advertiser/business` and `/creator/business`.
///
/// Loads [creatorBusinessProfileProvider] when [seeded] is null (deep link /
/// settings entry). Wallet CTAs pass a seeded profile via [GoRouterState.extra].
class BusinessInfoHostScreen extends ConsumerWidget {
  const BusinessInfoHostScreen({
    super.key,
    this.seeded,
    required this.useGlobalBilling,
  });

  final CreatorBusinessProfile? seeded;
  final bool useGlobalBilling;

  static BusinessInfoHostScreen fromGoState(
    GoRouterState state, {
    required bool useGlobalBilling,
  }) {
    CreatorBusinessProfile? seeded;
    var billing = useGlobalBilling;
    final extra = state.extra;
    if (extra is CreatorBusinessProfile) {
      seeded = extra;
    } else if (extra is Map) {
      final initial = extra['initial'];
      if (initial is CreatorBusinessProfile) {
        seeded = initial;
      }
      final flag = extra['useGlobalBilling'];
      if (flag is bool) {
        billing = flag;
      }
    }
    return BusinessInfoHostScreen(
      seeded: seeded,
      useGlobalBilling: billing,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider);
    // Advertiser-only accounts use world billing; dual-role creators keep Stripe list.
    final resolvedBilling = useGlobalBilling &&
        (user?.shouldUseAdvertiserGlobalBusinessSchema ?? useGlobalBilling);

    if (seeded != null) {
      return BusinessInfoScreen(
        initial: seeded!,
        useGlobalBilling: resolvedBilling,
      );
    }

    final async = ref.watch(creatorBusinessProfileProvider);
    return async.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.surfaceOf(context),
        appBar: AppBar(
          title: Text(context.t.creator.business.dialog_title),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surfaceOf(context),
        appBar: AppBar(
          title: Text(context.t.creator.business.dialog_title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorBanner(
            message: context.t.advertiser_wallet.business_profile_error,
            onRetry: () => ref.invalidate(creatorBusinessProfileProvider),
          ),
        ),
      ),
      data: (profile) => BusinessInfoScreen(
        initial: profile,
        useGlobalBilling: resolvedBilling,
      ),
    );
  }
}
