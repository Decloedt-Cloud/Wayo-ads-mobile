import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../providers/invoices_providers.dart';

/// Prev / next controls backed by server page metadata ([InvoicesState.page]).
class InvoiceListPaginationBar extends ConsumerWidget {
  const InvoiceListPaginationBar({super.key, required this.state});

  final InvoicesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    if (state.totalPages <= 1 && state.invoices.isEmpty) {
      return const SizedBox.shrink();
    }

    final canPrev = state.page > 1 && !state.isLoadingMore;
    final canNext = state.hasNextPage && !state.isLoadingMore;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: canPrev
                ? () {
                    HapticFeedback.selectionClick();
                    ref.read(invoicesControllerProvider.notifier).loadPrevious();
                  }
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: t.invoices.pagination_previous,
          ),
          Expanded(
            child: Text(
              t.invoices.pagination_meta
                  .replaceAll('{current}', '${state.page}')
                  .replaceAll('{total}', '${state.totalPages}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: canNext
                ? () {
                    HapticFeedback.selectionClick();
                    ref.read(invoicesControllerProvider.notifier).loadNext();
                  }
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: t.invoices.pagination_next,
          ),
        ],
      ),
    );
  }
}
