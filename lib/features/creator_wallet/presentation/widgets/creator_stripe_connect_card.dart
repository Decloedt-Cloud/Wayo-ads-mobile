import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/creator_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/creator_wallet_remote_datasource.dart';
import '../../domain/creator_wallet_models.dart';
import '../providers/creator_wallet_providers.dart';

/// Stripe Connect onboarding / Express dashboard card.
///
/// - Not connected ↦ "Connect Stripe" button → opens `/stripe-connect/onboard`.
/// - Connected but onboarding incomplete ↦ "Finish onboarding".
/// - Connected + onboarded ↦ pill "Connected" + "Open Stripe dashboard".
///
/// All mutations go through [url_launcher] in `externalApplication` mode so the
/// OS browser/Stripe app handles the sensitive flow (the mobile app never
/// stores keys or KYC PII).
///
/// [onBusinessInfoCorrection] is invoked from the SnackBar when Stripe fails
/// with an error that likely requires updating business / address fields on
/// Wayo-ads.
class CreatorStripeConnectCard extends ConsumerStatefulWidget {
  const CreatorStripeConnectCard({
    super.key,
    required this.status,
    this.onBusinessInfoCorrection,
  });

  final CreatorStripeStatus status;
  final Future<void> Function()? onBusinessInfoCorrection;

  @override
  ConsumerState<CreatorStripeConnectCard> createState() =>
      _CreatorStripeConnectCardState();
}

class _CreatorStripeConnectCardState
    extends ConsumerState<CreatorStripeConnectCard> {
  bool _loading = false;

  Future<void> _openOnboarding() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(creatorWalletRepositoryProvider);
      final url = await repo.createStripeOnboardingUrl();
      await _launchUrl(url);
    } catch (e) {
      if (!mounted) return;
      _handleStripeFailure(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDashboard() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(creatorWalletRepositoryProvider);
      final url = await repo.createStripeLoginUrl();
      await _launchUrl(url);
    } catch (e) {
      if (!mounted) return;
      _handleStripeFailure(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) throw StateError('Invalid url: $url');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw StateError('Cannot launch $url');
    // Refresh Stripe status when the user comes back from the browser.
    if (!mounted) return;
    // ignore: unused_result
    ref.refresh(creatorStripeStatusProvider);
  }

  void _handleStripeFailure(Object error) {
    final t = context.t;
    if (error is CreatorWalletApiException) {
      final msg =
          error.message.isNotEmpty ? error.message : t.creator.wallet.stripe_error;
      final showFixAction = error.mayBeFixedViaBusinessProfileEdit &&
          widget.onBusinessInfoCorrection != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            msg,
            style: const TextStyle(color: Colors.white),
          ),
          action: showFixAction
              ? SnackBarAction(
                  label: t.creator.wallet.stripe_edit_business_action,
                  textColor: Colors.white,
                  onPressed: () {
                    // ignore: discarded_futures
                    widget.onBusinessInfoCorrection!();
                  },
                )
              : null,
        ),
      );
      return;
    }
    _showError('$error');
  }

  void _showError(String msg) {
    final t = context.t;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          msg.isEmpty ? t.creator.wallet.stripe_error : msg,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final status = widget.status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (String title, String subtitle, IconData icon, Color accent) =
        _copyFor(t, status, context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.04,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: AppTextStyles.headlineMedium(
                                  context,
                                ).copyWith(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (status.canWithdraw)
                              _StatusPill(
                                label: t.creator.wallet.stripe_connected,
                                color: AppColors.success,
                              )
                            else if (status.connected &&
                                !status.onboardingCompleted)
                              _StatusPill(
                                label: t
                                    .creator
                                    .wallet
                                    .stripe_onboarding_required_pill,
                                color: Colors.amber,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodyLarge(
                            context,
                          ).copyWith(color: AppColors.textSecondaryOf(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildActions(t, status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(Translations t, CreatorStripeStatus status) {
    if (_loading) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(
                CreatorColors.primaryOf(context),
              ),
            ),
          ),
        ),
      );
    }
    if (!status.connected) {
      return _primaryButton(
        label: t.creator.wallet.stripe_connect_action,
        icon: Icons.link_rounded,
        onPressed: _openOnboarding,
      );
    }
    if (!status.onboardingCompleted || status.requirementsDue) {
      return _primaryButton(
        label: t.creator.wallet.stripe_complete_action,
        icon: Icons.check_circle_outline_rounded,
        onPressed: _openOnboarding,
      );
    }
    return Row(
      children: [
        Expanded(
          child: _primaryButton(
            label: t.creator.wallet.stripe_open_dashboard,
            icon: Icons.open_in_new_rounded,
            onPressed: _openDashboard,
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: CreatorColors.primaryOf(context),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  (String, String, IconData, Color) _copyFor(
    Translations t,
    CreatorStripeStatus s,
    BuildContext context,
  ) {
    if (!s.connected) {
      return (
        t.creator.wallet.stripe_card_title_disconnected,
        t.creator.wallet.stripe_card_subtitle_disconnected,
        Icons.link_rounded,
        CreatorColors.primaryOf(context),
      );
    }
    if (!s.onboardingCompleted || s.requirementsDue) {
      return (
        t.creator.wallet.stripe_card_title_incomplete,
        t.creator.wallet.stripe_card_subtitle_incomplete,
        Icons.pending_actions_rounded,
        Colors.amber.shade700,
      );
    }
    return (
      t.creator.wallet.stripe_card_title_connected,
      t.creator.wallet.stripe_card_subtitle_connected,
      Icons.verified_rounded,
      AppColors.success,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
