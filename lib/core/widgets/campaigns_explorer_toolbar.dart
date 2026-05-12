import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../campaigns/campaign_explorer_layout.dart';
import '../theme/app_colors.dart';
import '../../i18n/strings.g.dart';

/// Web-inspired “control strip”: search, filter row (wraps on narrow widths),
/// results caption, grid/list switch — tuned for dark & light international UIs.
class CampaignsExplorerToolbar extends StatelessWidget {
  const CampaignsExplorerToolbar({
    super.key,
    required this.searchField,
    this.filterScrollContent,
    this.onResetExplorerFilters,
    required this.filtersExpanded,
    required this.onFiltersExpandedChanged,
    required this.resultCountText,
    required this.layout,
    required this.onLayoutChanged,
  });

  final Widget searchField;
  final Widget? filterScrollContent;
  /// Shown below the filter row when non-null. Caller should reset explorer
  /// filter state and pagination to the first page.
  final VoidCallback? onResetExplorerFilters;
  /// When false, search + filters + reset are hidden (footer row stays visible).
  final bool filtersExpanded;
  final ValueChanged<bool> onFiltersExpandedChanged;
  final String resultCountText;
  final CampaignExplorerLayout layout;
  final ValueChanged<CampaignExplorerLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = AppColors.borderOf(context);
    final bg = isDark
        ? AppColors.surfaceElevatedOf(context).withValues(alpha: 0.4)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.72);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border.withValues(alpha: isDark ? 0.5 : 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: filtersExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        searchField,
                        if (filterScrollContent != null) ...[
                          const SizedBox(height: 12),
                          filterScrollContent!,
                          if (onResetExplorerFilters != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton.icon(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  onResetExplorerFilters!();
                                },
                                icon: Icon(
                                  Icons.restart_alt_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                label: Text(
                                  context.t.campaigns_explorer.reset_filters,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                        SizedBox(height: filterScrollContent != null ? 12 : 8),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    resultCountText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondaryOf(context),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: filtersExpanded
                      ? context.t.campaigns_explorer.toolbar_hide_search_filters
                      : context.t.campaigns_explorer.toolbar_show_search_filters,
                  child: IconButton(
                    tooltip: filtersExpanded
                        ? context
                            .t
                            .campaigns_explorer
                            .toolbar_hide_search_filters
                        : context
                            .t
                            .campaigns_explorer
                            .toolbar_show_search_filters,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onFiltersExpandedChanged(!filtersExpanded);
                    },
                    icon: Icon(
                      filtersExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 26,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _LayoutSegment(
                  layout: layout,
                  onChanged: onLayoutChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutSegment extends StatelessWidget {
  const _LayoutSegment({
    required this.layout,
    required this.onChanged,
  });

  final CampaignExplorerLayout layout;
  final ValueChanged<CampaignExplorerLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border.withValues(alpha: isDark ? 0.55 : 0.9),
        ),
        color: Theme.of(context).colorScheme.surface.withValues(
              alpha: isDark ? 0.2 : 0.45,
            ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LayoutIcon(
            icon: Icons.grid_view_rounded,
            selected: layout == CampaignExplorerLayout.grid,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(CampaignExplorerLayout.grid);
            },
          ),
          _LayoutIcon(
            icon: Icons.view_list_rounded,
            selected: layout == CampaignExplorerLayout.list,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(CampaignExplorerLayout.list);
            },
          ),
        ],
      ),
    );
  }
}

class _LayoutIcon extends StatelessWidget {
  const _LayoutIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final fg = selected ? primary : AppColors.textMutedOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: selected
                ? primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Icon(icon, size: 20, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Rounded filter control matching the web dropdown look.
class CampaignExplorerFilterChip extends StatelessWidget {
  const CampaignExplorerFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = AppColors.primary;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? primary.withValues(alpha: 0.55)
                    : AppColors.borderOf(context),
              ),
              color: selected
                  ? primary.withValues(alpha: 0.14)
                  : scheme.surface.withValues(alpha: 0.15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    letterSpacing: 0.05,
                    color: selected
                        ? primary
                        : AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: selected ? primary : AppColors.textMutedOf(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
