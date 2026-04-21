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
        title: Text(async.maybeWhen(
          data: (m) => (m['title'] as String?)?.trim().isNotEmpty == true
              ? m['title'] as String
              : (title ?? t.advertiser_campaigns.detail.fallback_title),
          orElse: () => title ?? t.advertiser_campaigns.detail.fallback_title,
        )),
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
              onRetry: () => ref.invalidate(advertiserCampaignDetailProvider(id)),
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

    final total = f != null ? cents('totalBudgetCents') : rootCents('totalBudgetCents');
    final remaining = f != null ? cents('remainingBudgetCents') : rootCents('remainingBudget');
    final spent = f != null ? cents('spentBudgetCents') : rootCents('spentBudget');
    final cpcRoot = (json['cpcCents'] as num?)?.toInt() ?? 0;

    final thumb = heroCoverUrl ??
        _firstAssetUrl(json['assets']) ??
        (json['coverUrl'] as String?);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Hero(
          tag: 'campaign_cover_$id',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: thumb != null && thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      errorWidget: (context, url, error) => _coverFallback(context),
                    )
                  : _coverFallback(context),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.headlineMedium(context).copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _DetailStatusChip(status: status, t: t),
          ],
        ),
        if (desc != null && desc.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(desc, style: AppTextStyles.bodyLarge(context)),
        ],
        const SizedBox(height: 24),
        Text(
          t.advertiser_campaigns.detail.metrics_title,
          style: AppTextStyles.labelLarge(context),
        ),
        const SizedBox(height: 12),
        _MetricRow(
          label: t.advertiser_campaigns.card.budget_total,
          value: MoneyFormatter.format(
            total / 100.0,
            currency: currency,
            locale: moneyLocale,
          ),
        ),
        _MetricRow(
          label: t.advertiser_campaigns.card.remaining,
          value: MoneyFormatter.format(
            remaining / 100.0,
            currency: currency,
            locale: moneyLocale,
          ),
        ),
        _MetricRow(
          label: t.advertiser_campaigns.card.spent,
          value: MoneyFormatter.format(
            spent / 100.0,
            currency: currency,
            locale: moneyLocale,
          ),
        ),
        _MetricRow(
          label: t.advertiser_campaigns.card.cpc,
          value: cpcRoot > 0
              ? MoneyFormatter.format(
                  cpcRoot / 100.0,
                  currency: currency,
                  locale: moneyLocale,
                )
              : '—',
        ),
        _MetricRow(
          label: t.advertiser_campaigns.detail.valid_views,
          value: '$validViews',
        ),
        _MetricRow(
          label: t.advertiser_campaigns.detail.approved_creators,
          value: '$approved',
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
      child: Icon(Icons.campaign_outlined, size: 48, color: AppColors.textMutedOf(context)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        color: AppColors.primary.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption(context).copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTextStyles.labelLarge(context).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
