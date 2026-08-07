import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/auth_runtime_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../../../core/ui/wayo_toast.dart';
import '../../../i18n/strings.g.dart';

/// Opens an existing advertiser DM for this campaign, or explains if none exists.
Future<void> openCampaignAdvertiserConversation(
  BuildContext context,
  WidgetRef ref, {
  required String campaignId,
}) async {
  final t = context.t.creator.campaigns;
  final dio = ref.read(wayoAdsDioProvider);
  final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
    ApiEndpoints.campaignAdvertiserConversation(campaignId),
  );
  try {
    final res = await dio.get<Map<String, dynamic>>(path);
    final data = res.data;
    final id = data?['conversationId'];
    if (id is num) {
      if (!context.mounted) return;
      context.push('/chat/thread/${id.toInt()}');
      return;
    }
    if (!context.mounted) return;
    WayoToast.info(context, t.chat_no_conversation);
  } on DioException catch (e) {
    if (!context.mounted) return;
    final code = e.response?.statusCode;
    if (code == 403) {
      WayoToast.warning(context, t.chat_forbidden);
    } else {
      WayoToast.error(context, t.chat_open_failed);
    }
  } catch (_) {
    if (!context.mounted) return;
    WayoToast.error(context, t.chat_open_failed);
  }
}
