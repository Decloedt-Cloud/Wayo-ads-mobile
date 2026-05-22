import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/domain/wayo_ads_account_role.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../shell/shell_tab_signed_in_gate.dart';
import '../../data/invoice_pdf_service.dart';
import '../../domain/invoice.dart';
import '../providers/invoices_providers.dart';
import '../widgets/invoice_advertiser_toolbar.dart';
import '../widgets/invoice_card.dart';
import '../widgets/invoice_date_filter_bar.dart';
import '../widgets/invoice_filter_bar.dart';
import '../widgets/invoice_list_pagination_bar.dart';
import '../widgets/invoices_empty_state.dart';
import '../widgets/invoices_hero_kpi.dart';

String _invoicesErrorDebugText(Object error) {
  if (error is AuthException) return error.toString();
  return '${error.runtimeType}: $error';
}

/// Invoices tab — role-aware (advertiser or creator endpoint), with hero KPI,
/// segmented filters, animated card grid, server pagination (prev/next),
/// pull-to-refresh and 60s foreground polling.
class InvoicesTabScreen extends StatelessWidget {
  const InvoicesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShellTabSignedInGate(
      builder: (context, ref, AppUser user) => _InvoicesTabBody(user: user),
    );
  }
}

class _InvoicesTabBody extends ConsumerStatefulWidget {
  const _InvoicesTabBody({required this.user});

  final AppUser user;

  @override
  ConsumerState<_InvoicesTabBody> createState() => _InvoicesTabBodyState();
}

class _InvoicesTabBodyState extends ConsumerState<_InvoicesTabBody>
    with WidgetsBindingObserver {
  final ScrollController _scrollCtrl = ScrollController();
  InvoicesPollingController? _pollingCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pollingCtrl = ref.read(invoicesPollingProvider.notifier);
      _pollingCtrl?.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _pollingCtrl?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _pollingCtrl;
    if (ctrl == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      ctrl.onAppLifecyclePaused();
    } else if (state == AppLifecycleState.resumed) {
      ctrl.onAppLifecycleResumed();
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final role = ref.read(currentWayoAdsAccountRoleProvider);
    if (invoicesUsePagedList(role)) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 220) {
      ref.read(invoicesControllerProvider.notifier).loadNext();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(invoicesControllerProvider.notifier).refresh();
  }

  Future<void> _onDownloadPdf(Invoice invoice) async {
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final pdfService = ref.read(invoicePdfServiceProvider);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(t.invoices.download_progress)),
          ],
        ),
        duration: const Duration(seconds: 12),
      ),
    );

    try {
      final File file = await pdfService.downloadAndSave(invoice);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              t.invoices.download_success.replaceAll(
                '{filename}',
                file.path.split(Platform.pathSeparator).last,
              ),
            ),
            action: SnackBarAction(
              label: t.invoices.action_open_pdf,
              onPressed: () => pdfService.open(file),
            ),
          ),
        );
    } on AuthException catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(t.invoices.download_error),
            backgroundColor: AppColors.error,
          ),
        );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(t.invoices.download_error),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WayoAdsAccountRole>(
      currentWayoAdsAccountRoleProvider,
      (prev, next) {
        // Skip first emission: [InvoicesController.build] already loads when role is known.
        if (prev == null) return;
        if (prev != next) {
          ref.invalidate(invoicesControllerProvider);
        }
      },
    );
    ref.listen<AppUser?>(currentAppUserProvider, (prev, next) {
      if (prev == null) return;
      if (next == null || prev.id != next.id) {
        ref.invalidate(invoicesControllerProvider);
      }
    });
    final t = context.t;
    final state = ref.watch(invoicesControllerProvider);
    final filtered = ref.watch(filteredInvoicesProvider);
    final isPolling = ref.watch(invoicesPollingProvider);
    final role = widget.user.wayoAdsRole;
    final locale = LocaleSettings.currentLocale.languageCode;

    final subtitle = role == WayoAdsAccountRole.creator
        ? t.invoices.subtitle_creator
        : t.invoices.subtitle_advertiser;
    final pageTitle = role == WayoAdsAccountRole.creator
        ? t.invoices.title_creator
        : t.invoices.title;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          edgeOffset: 8,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: Text(
                          pageTitle,
                          style: AppTextStyles.pageTitle(context),
                        ),
                      ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    InvoicesHeroKpi(role: role, isLive: isPolling),
                    const SizedBox(height: 16),
                    InvoiceFilterBar(role: role),
                    if (invoicesUsePagedList(role)) ...[
                      const SizedBox(height: 8),
                      const InvoiceDateFilterBar(),
                    ],
                    const InvoiceAdvertiserToolbar(),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            ...state.when(
              loading: () => [_buildSkeletonList(context)],
              error: (e, _) => [_buildError(context, e)],
              data: (s) {
                final list = filtered.valueOrNull ?? const <Invoice>[];
                if (list.isEmpty && !s.isLoadingMore) {
                  return [
                    // [hasScrollBody: true] avoids bottom overflow when the header
                    // (hero KPI + filters + toolbar) leaves less vertical space than
                    // [InvoicesEmptyState]'s intrinsic height on small viewports.
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Align(
                                alignment: Alignment.center,
                                child: InvoicesEmptyState(
                                  onRefresh: _onRefresh,
                                  subtitleOverride:
                                      role == WayoAdsAccountRole.creator
                                      ? context.t.invoices.empty_subtitle_creator
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ];
                }
                return _buildDataList(
                  context,
                  list,
                  locale,
                  s,
                  role: role,
                  hasMore: !invoicesUsePagedList(role) && s.hasNextPage,
                  isLoadingMore: s.isLoadingMore,
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
        ),
      ),
    );
  }

  List<Widget> _buildDataList(
    BuildContext context,
    List<Invoice> invoices,
    String locale,
    InvoicesState paging, {
    required WayoAdsAccountRole role,
    required bool hasMore,
    required bool isLoadingMore,
  }) {
    final usePageBar = invoicesUsePagedList(role);
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList.separated(
          itemCount: invoices.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final inv = invoices[i];
            return InvoiceCard(
              invoice: inv,
              locale: locale,
              onTap: () =>
                  context.push<void>('/invoices/${Uri.encodeComponent(inv.id)}'),
              onViewDetails: () {
                HapticFeedback.selectionClick();
                context.push<void>('/invoices/${Uri.encodeComponent(inv.id)}');
              },
              onDownloadPdf: () {
                HapticFeedback.selectionClick();
                _onDownloadPdf(inv);
              },
            )
                .animate()
                .fadeIn(duration: 320.ms, delay: (i * 30).ms)
                .slideY(begin: 0.06, end: 0, duration: 360.ms, curve: Curves.easeOut);
          },
        ),
      ),
      if (usePageBar)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InvoiceListPaginationBar(state: paging),
          ),
        ),
      if (isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
        ),
      if (!usePageBar && !hasMore && invoices.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text(
                paging.displayTotalPages > 1
                    ? context.t.invoices.pagination_detail
                        .replaceAll('{current}', '${paging.displayCurrentPage}')
                        .replaceAll('{total}', '${paging.displayTotalPages}')
                        .replaceAll('{count}', '${paging.totalCount}')
                    : '— ${context.t.invoices.summary_count} · ${paging.totalCount} —',
                style: TextStyle(
                  color: AppColors.textMutedOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildSkeletonList(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverList.separated(
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Skeletonizer(
          enabled: true,
          child: InvoiceCard(
            invoice: Invoice(
              id: 'skel',
              invoiceNumber: 'INV-2026-0001',
              type: InvoiceType.deposit,
              roleType: InvoiceRoleType.advertiser,
              status: InvoiceStatus.paid,
              totalAmountCents: 12500,
              taxAmountCents: 0,
              currency: 'EUR',
              referenceId: null,
              createdAt: DateTime.now(),
              paidAt: DateTime.now(),
            ),
            locale: 'en',
            onTap: () {},
            onViewDetails: () {},
            onDownloadPdf: () {},
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final t = context.t;
    return SliverFillRemaining(
      hasScrollBody: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              t.invoices.error_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.invoices.error_subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge(context),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              Text(
                'Debug (dev / verbose builds only)',
                style: TextStyle(
                  color: AppColors.textMutedOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    _invoicesErrorDebugText(error),
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final text = _invoicesErrorDebugText(error);
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied debug details')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('Copy debug details'),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t.invoices.empty_cta),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
