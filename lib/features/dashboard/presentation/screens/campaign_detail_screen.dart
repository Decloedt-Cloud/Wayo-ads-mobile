import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/format/money_formatter.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../advertiser_campaigns/presentation/providers/advertiser_campaigns_providers.dart';
import '../../domain/entities/campaign_status.dart';
import '../widgets/error_banner.dart';

String _moneyLocale(AppLocale l) => switch (l) {
  AppLocale.en => 'en_US',
  AppLocale.fr => 'fr_FR',
  AppLocale.ar => 'ar_SA',
};

/// Read-only campaign detail (Wayo-ads `GET /api/campaigns/:id`). No edit actions.
class CampaignDetailScreen extends ConsumerWidget {
  const CampaignDetailScreen({
    super.key,
    required this.id,
    this.coverUrl,
    this.title,
  });

  final String id;
  final String? coverUrl;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final locale = ref.watch(localeProvider);
    final moneyLocale = _moneyLocale(locale);
    final async = ref.watch(advertiserCampaignDetailProvider(id));
    String msg(Object e) {
      if (e is NetworkException) {
        return t.errors.network;
      }
      if (e is ServerException) {
        return e.message.isNotEmpty ? e.message : t.errors.server_generic;
      }
      return t.errors.server_generic;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: Text(
          async.maybeWhen(
            data: (m) => (m['title'] as String?)?.trim().isNotEmpty == true
                ? m['title'] as String
                : (title ?? t.advertiser_campaigns.detail.fallback_title),
            orElse: () => title ?? t.advertiser_campaigns.detail.fallback_title,
          ),
        ),
      ),
      body: async.when(
        data: (json) => _DetailContent(
          id: id,
          json: json,
          heroCoverUrl: coverUrl,
          fallbackTitle: title,
          moneyLocale: moneyLocale,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ErrorBanner(
              message: msg(e),
              retryLabel: t.dashboard.errors.retry,
              onRetry: () =>
                  ref.invalidate(advertiserCampaignDetailProvider(id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.id,
    required this.json,
    required this.heroCoverUrl,
    required this.fallbackTitle,
    required this.moneyLocale,
  });

  final String id;
  final Map<String, dynamic> json;
  final String? heroCoverUrl;
  final String? fallbackTitle;
  final String moneyLocale;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final title = (json['title'] as String?)?.trim().isNotEmpty == true
        ? json['title'] as String
        : (fallbackTitle ?? '');
    final status = CampaignStatus.fromString(json['status'] as String?);
    final desc = json['description'] as String?;
    final finance = json['finance'];
    final validViews = (json['validViews'] as num?)?.toInt() ?? 0;
    final approved = (json['approvedCreators'] as num?)?.toInt() ?? 0;
    final currency = 'EUR';
    Map<String, dynamic>? f;
    if (finance is Map<String, dynamic>) {
      f = finance;
    }
    int cents(dynamic k) {
      final v = f?[k];
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return int.tryParse('$v') ?? 0;
    }

    int rootCents(String k) {
      final v = json[k];
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return int.tryParse('$v') ?? 0;
    }

    final total = f != null
        ? cents('totalBudgetCents')
        : rootCents('totalBudgetCents');
    final remaining = f != null
        ? cents('remainingBudgetCents')
        : rootCents('remainingBudget');
    final spent = f != null
        ? cents('spentBudgetCents')
        : rootCents('spentBudget');
    // Prefer nested finance.cpcCents; otherwise root; default 0 (never "—" in UI).
    int cpcCents() {
      if (f != null) {
        final c = f['cpcCents'] ?? f['cpc'];
        if (c is int) {
          return c;
        }
        if (c is num) {
          return c.toInt();
        }
      }
      return (json['cpcCents'] as num?)?.toInt() ?? 0;
    }

    final cpcRoot = cpcCents();

    final thumb =
        heroCoverUrl ??
        _firstAssetUrl(json['assets']) ??
        (json['coverUrl'] as String?);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      children: [
        Hero(
          tag: 'campaign_cover_$id',
          child: _CoverFrame(
            isDark: isDark,
            child: thumb != null && thumb.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: thumb,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    errorWidget: (context, url, error) =>
                        _coverFallback(context),
                  )
                : _coverFallback(context),
          ),
        ),
        const SizedBox(height: 20),
        _SummaryCard(
          isDark: isDark,
          title: title,
          status: status,
          desc: desc,
          t: t,
        ),
        const SizedBox(height: 20),
        Text(
          t.advertiser_campaigns.detail.metrics_title,
          style: AppTextStyles.labelLarge(context).copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: AppColors.textMutedOf(context),
          ),
        ),
        const SizedBox(height: 12),
        _MetricsCard(
          isDark: isDark,
          child: Column(
            children: [
              _MetricTile(
                isDark: isDark,
                icon: Icons.payments_outlined,
                label: t.advertiser_campaigns.card.budget_total,
                value: MoneyFormatter.format(
                  total / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                ),
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.savings_outlined,
                label: t.advertiser_campaigns.card.remaining,
                value: MoneyFormatter.format(
                  remaining / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                ),
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.trending_down_rounded,
                label: t.advertiser_campaigns.card.spent,
                value: MoneyFormatter.format(
                  spent / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                ),
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.toll_outlined,
                label: t.advertiser_campaigns.card.cpc,
                value: MoneyFormatter.format(
                  cpcRoot / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                ),
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.visibility_outlined,
                label: t.advertiser_campaigns.detail.valid_views,
                value: '$validViews',
              ),
              _MetricDivider(isDark: isDark),
              _MetricTile(
                isDark: isDark,
                icon: Icons.groups_2_outlined,
                label: t.advertiser_campaigns.detail.approved_creators,
                value: '$approved',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _firstAssetUrl(dynamic assets) {
    if (assets is! List) {
      return null;
    }
    for (final e in assets) {
      if (e is Map<String, dynamic>) {
        final u = e['url'] as String?;
        if (u != null && u.isNotEmpty) {
          return u;
        }
      }
    }
    return null;
  }

  Widget _coverFallback(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceElevatedOf(context),
      child: Icon(
        Icons.campaign_outlined,
        size: 48,
        color: AppColors.textMutedOf(context),
      ),
    );
  }
}

class _CoverFrame extends StatelessWidget {
  const _CoverFrame({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 72,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: isDark ? 0.55 : 0.35),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.isDark,
    required this.title,
    required this.status,
    required this.desc,
    required this.t,
  });

  final bool isDark;
  final String title;
  final CampaignStatus status;
  final String? desc;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevatedOf(context),
            AppColors.primary.withValues(alpha: isDark ? 0.07 : 0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headlineMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _DetailStatusChip(status: status, t: t),
            ],
          ),
          if (desc != null && desc!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              desc!.trim(),
              style: AppTextStyles.bodyLarge(context).copyWith(
                height: 1.45,
                color: AppColors.textPrimaryOf(context).withValues(alpha: 0.88),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.surfaceElevatedOf(
          context,
        ).withValues(alpha: isDark ? 0.92 : 0.98),
        border: Border.all(
          color: AppColors.borderOf(
            context,
          ).withValues(alpha: isDark ? 0.5 : 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: child,
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.borderOf(
          context,
        ).withValues(alpha: isDark ? 0.4 : 0.7),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
  });

  final bool isDark;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 15,
                color: AppColors.textMutedOf(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTextStyles.labelLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip({required this.status, required this.t});

  final CampaignStatus status;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      CampaignStatus.active => t.advertiser_campaigns.status.active,
      CampaignStatus.paused => t.advertiser_campaigns.status.paused,
      CampaignStatus.completed => t.advertiser_campaigns.status.completed,
      CampaignStatus.draft => t.advertiser_campaigns.status.draft,
      CampaignStatus.unknown => t.advertiser_campaigns.status.other,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
