import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

const Color _filterActiveAmber = Color(0xFFF59E0B);
const Color _filterActiveFill = Color(0xFF1A1400);

/// Compact filter control for campaign explorers. Uses [DropdownButton] instead
/// of [PopupMenuButton] so selection updates reliably in toolbars.
class CampaignExplorerFilterMenu extends StatelessWidget {
  const CampaignExplorerFilterMenu({
    super.key,
    this.caption,
    this.isActive = false,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
  });

  /// Small label above the field (e.g. "Type", "Status").
  final String? caption;

  /// Whether this filter is narrowed from its default — adds brand accent.
  final bool isActive;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isActive ? _filterActiveAmber : AppColors.borderOf(context);
    final fill = isActive
        ? _filterActiveFill
        : Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: isDark ? 0.14 : 0.55);

    final dropdown = Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: isActive ? 1.5 : 1,
        ),
        color: fill,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _filterActiveAmber.withValues(alpha: isDark ? 0.18 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
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
              color:
                  isActive ? _filterActiveAmber : AppColors.textMutedOf(context),
            ),
          ),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.02,
            color:
                isActive ? _filterActiveAmber : AppColors.textPrimaryOf(context),
          ),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          menuMaxHeight: 360,
          selectedItemBuilder: (ctx) => [
            for (final (_, lab) in items)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  children: [
                    if (isActive) ...[
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsetsDirectional.only(end: 8),
                        decoration: const BoxDecoration(
                          color: _filterActiveAmber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        lab,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.02,
                          color: isActive
                              ? _filterActiveAmber
                              : AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                  ],
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
                              color: _filterActiveAmber,
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
    );

    if (caption == null || caption!.isEmpty) {
      return dropdown;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 3, bottom: 6),
          child: Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.65,
              height: 1.1,
              color: isActive ? _filterActiveAmber : AppColors.textMutedOf(context),
            ),
          ),
        ),
        dropdown,
      ],
    );
  }
}
