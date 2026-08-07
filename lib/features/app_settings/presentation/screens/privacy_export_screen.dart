import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../router/app_router.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';

Future<void> openPrivacyExportScreen({VoidCallback? onClosePanel}) async {
  onClosePanel?.call();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = rootNavigatorKey.currentContext;
    if (nav != null && nav.mounted) {
      GoRouter.of(nav).push('/settings/privacy');
    }
  });
}

final class UserDataExportRemote {
  UserDataExportRemote(this._dio);
  final Dio _dio;

  Future<Uint8List> downloadExportJson() async {
    final path = AuthRuntimeConfig.instance.wayoAdsRequestPath(
      ApiEndpoints.userExportData,
    );
    try {
      final res = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = res.data;
      if (data == null || data.isEmpty) {
        throw const ServerException('Empty export');
      }
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      if (e.response?.statusCode == 401) {
        throw const SessionInvalidException();
      }
      throw ServerException(
        e.message ?? 'Export failed',
        e.response?.statusCode,
      );
    }
  }
}

final userDataExportRemoteProvider = Provider<UserDataExportRemote>((ref) {
  return UserDataExportRemote(ref.watch(wayoAdsDioProvider));
});

class PrivacyExportScreen extends ConsumerStatefulWidget {
  const PrivacyExportScreen({super.key});

  @override
  ConsumerState<PrivacyExportScreen> createState() =>
      _PrivacyExportScreenState();
}

class _PrivacyExportScreenState extends ConsumerState<PrivacyExportScreen> {
  var _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    final t = context.t.app_settings;
    setState(() => _busy = true);
    WayoToast.info(context, t.export_data_progress);
    try {
      await awaitPostLoginBootstrapReader(ref);
      final bytes =
          await ref.read(userDataExportRemoteProvider).downloadExportJson();
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      final file = File('${dir.path}/wayo-ads-data-export-$stamp.json');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: t.export_data_title,
      );
      if (mounted) WayoToast.success(context, t.export_data_success);
    } catch (e) {
      if (mounted) {
        WayoToast.error(
          context,
          e is AuthException ? e.toString() : t.export_data_error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.app_settings;
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(t.export_data_title),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.export_data_sub),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _export();
                    },
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(t.export_data_button),
            ),
          ],
        ),
      ),
    );
  }
}
