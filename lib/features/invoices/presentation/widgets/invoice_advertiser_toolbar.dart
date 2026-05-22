import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../providers/invoices_providers.dart';

/// Search field for invoice / statement lists (dates via [InvoiceDateFilterBar]).
class InvoiceAdvertiserToolbar extends ConsumerStatefulWidget {
  const InvoiceAdvertiserToolbar({super.key});

  @override
  ConsumerState<InvoiceAdvertiserToolbar> createState() =>
      _InvoiceAdvertiserToolbarState();
}

class _InvoiceAdvertiserToolbarState
    extends ConsumerState<InvoiceAdvertiserToolbar> {
  late final TextEditingController _searchCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearchDebounced(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = v.trim();
      if (!mounted) return;
      ref.read(invoiceSearchQueryProvider.notifier).state = q;
      final role = ref.read(currentWayoAdsAccountRoleProvider);
      if (invoicesUsePagedList(role)) {
        ref.invalidate(invoicesControllerProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final role = ref.watch(currentWayoAdsAccountRoleProvider);
    if (!invoicesUsePagedList(role)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _applySearchDebounced,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: AppColors.textPrimaryOf(context),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: t.invoices.search_hint,
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: AppColors.textMutedOf(context),
          ),
          filled: true,
          fillColor: AppColors.surfaceElevatedOf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
