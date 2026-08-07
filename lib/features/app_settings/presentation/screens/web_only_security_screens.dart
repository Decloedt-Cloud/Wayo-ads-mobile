import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/config/auth_runtime_config.dart';
import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/wayo_ads_dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../router/app_router.dart';
import '../../../creator/presentation/providers/creator_session_gate.dart';

Future<void> openPasskeysInfoScreen({VoidCallback? onClosePanel}) async {
  onClosePanel?.call();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = rootNavigatorKey.currentContext;
    if (nav != null && nav.mounted) {
      GoRouter.of(nav).push('/settings/passkeys');
    }
  });
}

Future<void> openConnectedAccountsInfoScreen({
  VoidCallback? onClosePanel,
}) async {
  onClosePanel?.call();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = rootNavigatorKey.currentContext;
    if (nav != null && nav.mounted) {
      GoRouter.of(nav).push('/settings/connected-accounts');
    }
  });
}

final class SettingsHandoffRemote {
  SettingsHandoffRemote(this._dio);
  final Dio _dio;

  String _path(String endpoint) =>
      AuthRuntimeConfig.instance.wayoAdsRequestPath(endpoint);

  Future<Uri> fetchHandoffUri(String endpoint) async {
    try {
      final res = await _dio.get<Object?>(
        _path(endpoint),
        queryParameters: const <String, dynamic>{'format': 'json'},
        options: Options(
          headers: const <String, dynamic>{'Accept': 'application/json'},
          followRedirects: false,
          validateStatus: (code) => code != null && code >= 200 && code < 400,
        ),
      );
      final data = res.data;
      if (data is Map && data['url'] is String && '${data['url']}'.isNotEmpty) {
        return Uri.parse('${data['url']}');
      }
      // Some proxies may still 302 — capture Location.
      final loc = res.headers.value('location');
      if (loc != null && loc.isNotEmpty) {
        return Uri.parse(loc);
      }
      throw const ServerException('Invalid handoff response');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const SessionInvalidException();
      }
      throw ServerException(
        e.message ?? 'Handoff failed',
        e.response?.statusCode,
      );
    }
  }
}

final settingsHandoffRemoteProvider = Provider<SettingsHandoffRemote>((ref) {
  return SettingsHandoffRemote(ref.watch(wayoAdsDioProvider));
});

class PasskeysInfoScreen extends ConsumerWidget {
  const PasskeysInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.app_settings;
    return _HandoffLaunchScreen(
      title: t.passkeys_title,
      body: t.passkeys_manage_hint,
      buttonLabel: t.passkeys_open_manage,
      endpoint: ApiEndpoints.passkeysHandoff,
    );
  }
}

class ConnectedAccountsInfoScreen extends ConsumerWidget {
  const ConnectedAccountsInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.app_settings;
    return _HandoffLaunchScreen(
      title: t.connected_accounts_title,
      body: t.connected_accounts_manage_hint,
      buttonLabel: t.connected_accounts_open_manage,
      endpoint: ApiEndpoints.connectedAccountsHandoff,
    );
  }
}

class _HandoffLaunchScreen extends ConsumerStatefulWidget {
  const _HandoffLaunchScreen({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.endpoint,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final String endpoint;

  @override
  ConsumerState<_HandoffLaunchScreen> createState() =>
      _HandoffLaunchScreenState();
}

class _HandoffLaunchScreenState extends ConsumerState<_HandoffLaunchScreen> {
  var _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await awaitPostLoginBootstrapReader(ref);
      final uri = await ref
          .read(settingsHandoffRemoteProvider)
          .fetchHandoffUri(widget.endpoint);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AuthHandoffWebViewScreen(
            title: widget.title,
            initialUrl: uri,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      WayoToast.error(
        context,
        e is AuthException ? e.toString() : context.t.app_settings.handoff_error,
      );
      // Fallback: public web settings.
      final base = AuthRuntimeConfig.instance.resolvedWayoAdsBaseUrl
          .replaceAll(RegExp(r'/+$'), '');
      final origin = base.replaceFirst(RegExp(r'/api$'), '');
      await launchUrl(
        Uri.parse('$origin/settings?tab=security'),
        mode: LaunchMode.externalApplication,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.body),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _open();
                    },
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen WebView for Auth_Wayo handoff (cookies required for WebAuthn).
class AuthHandoffWebViewScreen extends StatefulWidget {
  const AuthHandoffWebViewScreen({
    super.key,
    required this.title,
    required this.initialUrl,
  });

  final String title;
  final Uri initialUrl;

  @override
  State<AuthHandoffWebViewScreen> createState() =>
      _AuthHandoffWebViewScreenState();
}

class _AuthHandoffWebViewScreenState extends State<AuthHandoffWebViewScreen> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(widget.initialUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            onPressed: () => launchUrl(
              widget.initialUrl,
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_browser_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
