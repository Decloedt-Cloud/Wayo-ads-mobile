import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../router/app_router.dart';

Future<void> openGuidesScreen({VoidCallback? onClosePanel}) async {
  onClosePanel?.call();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = rootNavigatorKey.currentContext;
    if (nav != null && nav.mounted) {
      GoRouter.of(nav).push('/resources');
    }
  });
}

/// Native in-app resources hub (no external browser redirect).
class GuidesResourcesScreen extends StatelessWidget {
  const GuidesResourcesScreen({super.key});

  static const _pages = <_ResourcePage>[
    _ResourcePage(
      id: 'hub',
      title: 'Resources hub',
      icon: Icons.auto_stories_rounded,
      sections: [
        (
          'Welcome',
          'Guides for advertisers and creators — campaign setup, billing, '
              'Content Lab, and FAQ. Everything opens inside the app.',
        ),
        (
          'How to use',
          'Pick a topic below. Each guide mirrors the Wayo Ads web resources '
              'without leaving the mobile app.',
        ),
      ],
    ),
    _ResourcePage(
      id: 'for-brands',
      title: 'For brands',
      icon: Icons.campaign_rounded,
      sections: [
        (
          'Reach creators',
          'Launch LINK, VIDEO, or SHORTS campaigns and let creators apply. '
              'Budget locks from your wallet when you publish.',
        ),
        (
          'Performance',
          'Track clicks, views, and spend from the Campaigns tab. Pause or '
              'adjust anytime.',
        ),
      ],
    ),
    _ResourcePage(
      id: 'about',
      title: 'About Wayo',
      icon: Icons.info_outline_rounded,
      sections: [
        (
          'What is Wayo Ads?',
          'Wayo Ads connects brands with YouTube creators for performance '
              'campaigns — traffic, views, and Shorts — with transparent CPC/CPM pricing.',
        ),
        (
          'Accounts',
          'Sign in with Wayo Auth. Choose Advertiser or Creator workspace. '
              'Superadmins manage users and payouts from the admin shell.',
        ),
      ],
    ),
    _ResourcePage(
      id: 'getting-started',
      title: 'Getting started',
      icon: Icons.rocket_launch_rounded,
      sections: [
        (
          '1. Complete your profile',
          'Add business information (required for advertiser deposits) and '
              'verify email.',
        ),
        (
          '2. Fund your wallet',
          'Use Card, ACH (USD), or Wire from Portefeuille. Card is instant; '
              'ACH and wire settle in 1–3 business days.',
        ),
        (
          '3. Create a campaign',
          'Choose type, niche, budget, end date, then publish. Budget + fees '
              'lock from your available balance.',
        ),
      ],
    ),
    _ResourcePage(
      id: 'create-campaign',
      title: 'Create a campaign',
      icon: Icons.add_box_outlined,
      sections: [
        (
          'Campaign types',
          'LINK (CPC traffic), VIDEO (CPM long-form), SHORTS (CPM vertical). '
              'Objective is set automatically from the type.',
        ),
        (
          'Budget & end date',
          'Set total budget, CPC/CPM, and an end date with the calendar picker. '
              'Review estimates before activating.',
        ),
        (
          'Geo targeting',
          'Optional country / city / radius. Worldwide is the default.',
        ),
      ],
    ),
    _ResourcePage(
      id: 'billing',
      title: 'Billing',
      icon: Icons.account_balance_wallet_outlined,
      sections: [
        (
          'Deposits',
          'Card (instant), ACH bank debit (USD, lower fee), or wire transfer '
              '(USD / EUR / GBP). Complete Business Information first.',
        ),
        (
          'Invoices & statements',
          'Download individual PDFs from Factures. Bulk ZIP download is not '
              'available on mobile — open each document instead.',
        ),
      ],
    ),
    _ResourcePage(
      id: 'content-lab',
      title: 'Content Lab',
      icon: Icons.science_outlined,
      sections: [
        (
          'AI tools',
          'Use Content Lab / Creator Studio for hooks, scripts, packaging, '
              'and spy tools. AI credits are managed separately from ad wallet funds.',
        ),
        (
          'Mobile',
          'Open Creator Studio from More when available, or continue on web '
              'for advanced lab workflows.',
        ),
      ],
    ),
    _ResourcePage(
      id: 'faq',
      title: 'FAQ',
      icon: Icons.help_outline_rounded,
      sections: [
        (
          'Why is my deposit pending?',
          'ACH and wire are not instant. You’ll see a processing banner until '
              'Stripe confirms funds — usually 1–3 business days.',
        ),
        (
          'Why can’t I publish?',
          'Check wallet balance covers budget + platform fee + tax, and that '
              'all required fields (title, niche, end date, landing/assets) are valid.',
        ),
        (
          'Chat pin / archive',
          'Tap the ⋮ menu on a conversation to pin or archive. Changes sync in '
              'real time over the chat websocket.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t.app_settings;
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(t.guides_title),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _pages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final page = _pages[i];
          return Material(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              leading: Icon(page.icon, color: AppColors.primary),
              title: Text(page.title),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _NativeResourceDetail(page: page),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ResourcePage {
  const _ResourcePage({
    required this.id,
    required this.title,
    required this.icon,
    required this.sections,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<(String, String)> sections;
}

class _NativeResourceDetail extends StatelessWidget {
  const _NativeResourceDetail({required this.page});
  final _ResourcePage page;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(page.title),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(page.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  page.title,
                  style: AppTextStyles.headlineMedium(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          for (final section in page.sections) ...[
            Text(
              section.$1,
              style: AppTextStyles.labelLarge(context).copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              section.$2,
              style: AppTextStyles.bodyLarge(context).copyWith(height: 1.45),
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}
