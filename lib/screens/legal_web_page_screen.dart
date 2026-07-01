import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/legal/wayo_legal_urls.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/ui/wayo_toast.dart';
import '../i18n/strings.g.dart';
import '../shared/widgets/language_switcher.dart';
import '../shared/widgets/theme_toggle_button.dart';

/// In-app viewer for Terms / Privacy hosted on the Wayo-ads website.
class LegalWebPageScreen extends ConsumerStatefulWidget {
  const LegalWebPageScreen({super.key, required this.document});

  final WayoLegalDocument document;

  @override
  ConsumerState<LegalWebPageScreen> createState() => _LegalWebPageScreenState();
}

class _LegalWebPageScreenState extends ConsumerState<LegalWebPageScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _loadFailed = false;
  late Uri _uri;

  @override
  void initState() {
    super.initState();
    _uri = WayoLegalUrls.uriFor(widget.document, LocaleSettings.currentLocale);
    _initController(_uri);
  }

  /// Hosts the in-app WebView is allowed to render. Any other destination
  /// (external links tapped inside the legal page) is opened in the system
  /// browser instead of being loaded in this authenticated-app WebView.
  bool _isAllowedNavigationHost(String url) {
    final target = Uri.tryParse(url);
    if (target == null) return false;
    final scheme = target.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') return false;
    final host = target.host.toLowerCase();
    if (host.isEmpty) return false;

    final allowedHosts = <String>{
      _uri.host.toLowerCase(),
      Uri.tryParse(WayoLegalUrls.origin)?.host.toLowerCase() ?? '',
    }..removeWhere((h) => h.isEmpty);

    for (final a in allowedHosts) {
      if (host == a || host.endsWith('.$a')) return true;
    }
    return false;
  }

  void _initController(Uri uri) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_isAllowedNavigationHost(request.url)) {
              return NavigationDecision.navigate;
            }
            unawaited(
              launchUrl(
                Uri.parse(request.url),
                mode: LaunchMode.externalApplication,
              ),
            );
            return NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _loadFailed = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _loadFailed = true;
            });
          },
        ),
      )
      ..loadRequest(uri);
    _controller = controller;
  }

  @override
  void didUpdateWidget(covariant LegalWebPageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) {
      _reloadForLocale();
    }
  }

  void _reloadForLocale() {
    final locale = ref.read(localeProvider);
    final uri = WayoLegalUrls.uriFor(widget.document, locale);
    if (uri == _uri) return;
    _uri = uri;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    _controller?.loadRequest(uri);
  }

  String _title(Translations t) => switch (widget.document) {
        WayoLegalDocument.terms => t.login.terms,
        WayoLegalDocument.privacy => t.login.privacy,
      };

  Future<void> _openInBrowser() async {
    final ok = await launchUrl(_uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      WayoToast.info(context, _uri.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppLocale>(localeProvider, (previous, next) {
      if (previous != next) _reloadForLocale();
    });

    final t = context.t;
    final controller = _controller;

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryOf(context),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: Text(
          _title(t),
          style: AppTextStyles.pageTitle(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _openInBrowser,
            icon: Icon(
              Icons.open_in_new_rounded,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 4),
          const LanguageSwitcher(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (controller != null && !_loadFailed)
              WebViewWidget(controller: controller),
            if (_loadFailed)
              _ErrorState(
                onRetry: () {
                  setState(() {
                    _loading = true;
                    _loadFailed = false;
                  });
                  controller?.loadRequest(_uri);
                },
                onOpenBrowser: _openInBrowser,
              ),
            if (_loading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.onRetry,
    required this.onOpenBrowser,
  });

  final VoidCallback onRetry;
  final VoidCallback onOpenBrowser;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load this page.',
              style: AppTextStyles.bodyLarge(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onOpenBrowser,
              child: const Text('Open in browser'),
            ),
          ],
        ),
      ),
    );
  }
}
