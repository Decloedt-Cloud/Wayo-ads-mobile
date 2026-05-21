import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../campaigns/campaign_explorer_layout.dart';
import '../theme/app_colors.dart';
import '../../i18n/strings.g.dart';

const Color _layoutToggleAmber = Color(0xFFF59E0B);
const Color _layoutToggleOnIcon = Color(0xFF0A0A0F);

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
    final innerBg = isDark
        ? const Color(0xFF161616)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.85);
    final outerBg = isDark ? AppColors.surfaceElevatedOf(context) : scheme.surface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.primary.withValues(alpha: 0.02),
                  outerBg.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.35, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  scheme.surface.withValues(alpha: 0.001),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? innerBg : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: border.withValues(alpha: isDark ? 0.45 : 0.88),
          ),
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
                            const SizedBox(height: 16),
                            filterScrollContent!,
                            if (onResetExplorerFilters != null) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: OutlinedButton.icon(
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(
                                      color: AppColors.primary.withValues(
                                        alpha: isDark ? 0.55 : 0.45,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    visualDensity: VisualDensity.compact,
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
                        color: filtersExpanded
                            ? _layoutToggleAmber
                            : AppColors.textSecondaryOf(context),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(
            alpha: isDark ? 0.5 : 0.88,
          ),
        ),
        color: isDark
            ? const Color(0xFF13131A).withValues(alpha: 0.92)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
      ),
      padding: const EdgeInsets.all(3),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: selected ? _layoutToggleAmber : Colors.transparent,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _layoutToggleAmber.withValues(alpha: 0.32),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(
              icon,
              size: 20,
              color: selected ? _layoutToggleOnIcon : AppColors.textMutedOf(context),
            ),
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
