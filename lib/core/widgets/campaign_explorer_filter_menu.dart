import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Compact filter control for campaign explorers. Uses [DropdownButton] instead
/// of [PopupMenuButton] so selection updates reliably in toolbars.
class CampaignExplorerFilterMenu extends StatelessWidget {
  const CampaignExplorerFilterMenu({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
  });

  final String? selectedValue;
  final List<(String?, String)> items;
  final ValueChanged<String?> onChanged;

  bool _itemSelected(String? v) =>
      v == null ? selectedValue == null : v == selectedValue;

  /// Dropdown value must appear in [items] or be null (“All …”).
  String? _valueOrFallback(List<(String?, String)> list) {
    if (selectedValue == null) return null;
    return list.any((e) => e.$1 == selectedValue) ? selectedValue : null;
  }

  @override
  Widget build(BuildContext context) {
    final value = _valueOrFallback(items);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 148),
        padding: const EdgeInsetsDirectional.only(start: 10, end: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderOf(context)),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: value,
            isDense: true,
            isExpanded: true,
            iconSize: 22,
            icon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 2),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: AppColors.textMutedOf(context),
              ),
            ),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: AppColors.textPrimaryOf(context),
            ),
            dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            menuMaxHeight: 360,
            selectedItemBuilder: (ctx) => [
              for (final (_, lab) in items)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    lab,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
            ],
            items: [
              for (final (v, lab) in items)
                DropdownMenuItem<String?>(
                  value: v,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: _itemSelected(v)
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          lab,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}
