import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';

/// Compact AI match + YouTube insights for application review (no Content Spy).
class ApplicationCreatorInsightsPanel extends ConsumerStatefulWidget {
  const ApplicationCreatorInsightsPanel({
    super.key,
    required this.campaignId,
    required this.creatorId,
    required this.applicationStatusApi,
  });

  final String campaignId;
  final String creatorId;
  final String applicationStatusApi;

  @override
  ConsumerState<ApplicationCreatorInsightsPanel> createState() =>
      _ApplicationCreatorInsightsPanelState();
}

class _ApplicationCreatorInsightsPanelState
    extends ConsumerState<ApplicationCreatorInsightsPanel> {
  Map<String, dynamic>? _match;
  Map<String, dynamic>? _insights;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final dio = ref.read(wayoAdsDioProvider);
    final cfg = AuthRuntimeConfig.instance;
    final status = widget.applicationStatusApi;
    try {
      if (refresh) {
        await dio.post(
          cfg.wayoAdsRequestPath(
            ApiEndpoints.campaignCreatorAiMatchScoreRefresh(
              widget.campaignId,
              widget.creatorId,
            ),
          ),
          queryParameters: {'status': status},
        );
        await dio.post(
          cfg.wayoAdsRequestPath(
            ApiEndpoints.campaignCreatorInsightsRefresh(
              widget.campaignId,
              widget.creatorId,
            ),
          ),
          queryParameters: {'status': status},
        );
      }
      final matchRes = await dio.get<Map<String, dynamic>>(
        cfg.wayoAdsRequestPath(
          ApiEndpoints.campaignCreatorAiMatchScore(
            widget.campaignId,
            widget.creatorId,
          ),
        ),
        queryParameters: {'status': status},
      );
      final insightsRes = await dio.get<Map<String, dynamic>>(
        cfg.wayoAdsRequestPath(
          ApiEndpoints.campaignCreatorInsights(
            widget.campaignId,
            widget.creatorId,
          ),
        ),
        queryParameters: {'status': status},
      );
      if (!mounted) return;
      setState(() {
        _match = matchRes.data;
        _insights = insightsRes.data;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            e.response?.data is Map &&
                (e.response!.data as Map)['error'] is String
            ? (e.response!.data as Map)['error'] as String
            : context.t.advertiser_campaigns.applications.insights_error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.t.advertiser_campaigns.applications.insights_error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.advertiser_campaigns.applications;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_error!, style: AppTextStyles.caption(context)),
          TextButton(onPressed: () => _load(), child: Text(t.insights_retry)),
        ],
      );
    }

    final score = _match?['score'];
    final contentQuality = _match?['contentQuality'];
    final brandSafety = _match?['brandSafety'];
    final ytLinked = _insights?['youtubeLinked'] == true;
    final channelName = _insights is Map && _insights!['channel'] is Map
        ? (_insights!['channel'] as Map)['channelName']
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.insights_title, style: AppTextStyles.labelLarge(context)),
        const SizedBox(height: 8),
        Text(
          [
            if (score != null) t.match_score(score: score),
            if (contentQuality != null)
              t.content_quality(value: '$contentQuality'),
            if (brandSafety != null) t.brand_safety(value: '$brandSafety'),
            ytLinked
                ? t.yt_linked(name: '${channelName ?? 'YouTube'}')
                : t.yt_unlinked,
          ].join(' · '),
          style: AppTextStyles.caption(context),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _load(refresh: true),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(t.insights_refresh),
          ),
        ),
      ],
    );
  }
}
