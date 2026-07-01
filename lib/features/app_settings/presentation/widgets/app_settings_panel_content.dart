import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/review/app_review_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../i18n/strings.g.dart';
import '../../../profile/presentation/providers/user_profile_providers.dart';
import 'app_settings_notifications_tile.dart';
import 'profile_settings_entry_tile.dart';
import '../../../account_deletion/presentation/widgets/account_deletion_settings_section.dart';
import '../../../security/presentation/widgets/security_settings_entry_tile.dart';

class AppSettingsPanelContent extends ConsumerWidget {
  const AppSettingsPanelContent({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final user = ref.watch(currentAppUserProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final avatarUrl = resolveProfileAvatarForDisplay(
      profile: profile,
      authUser: user,
    );
    final displayName = resolveProfileDisplayName(
      profile: profile,
      authUser: user,
      fallback: t.app_settings.profile_fallback,
    );

    final core = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(
          onClose: onClose,
          displayName: displayName,
          email: user?.email,
          avatarUrl: avatarUrl,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileSettingsEntryTile(onClose: onClose)
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.03),
                const SizedBox(height: 22),
                _SectionTitle(
                      icon: Icons.palette_outlined,
                      text: t.app_settings.section_appearance,
                    )
                    .animate()
                    .fadeIn(duration: 220.ms)
                    .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                const SizedBox(height: 10),
                _AppearanceCard(
                      themeMode: themeMode,
                      onThemeChanged: (m) {
                        HapticFeedback.selectionClick();
                        ref.read(themeModeProvider.notifier).set(m);
                      },
                    )
                    .animate()
                    .fadeIn(delay: 40.ms, duration: 260.ms)
                    .slideY(begin: 0.03),
                const SizedBox(height: 8),
                Text(
                  t.app_settings.theme_hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                      icon: Icons.language_rounded,
                      text: t.app_settings.section_language,
                    )
                    .animate()
                    .fadeIn(delay: 60.ms, duration: 220.ms)
                    .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                const SizedBox(height: 10),
                _LanguageColumn(
                      selected: locale,
                      onSelect: (l) {
                        HapticFeedback.lightImpact();
                        ref.read(localeProvider.notifier).set(l);
                      },
                    )
                    .animate()
                    .fadeIn(delay: 90.ms, duration: 260.ms)
                    .slideY(begin: 0.03),
                const SizedBox(height: 8),
                Text(
                  t.app_settings.language_hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                      icon: Icons.notifications_outlined,
                      text: t.app_settings.section_notifications,
                    )
                    .animate()
                    .fadeIn(delay: 95.ms, duration: 220.ms)
                    .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                const SizedBox(height: 10),
                const AppSettingsNotificationsTile()
                    .animate()
                    .fadeIn(delay: 105.ms, duration: 260.ms)
                    .slideY(begin: 0.03),
                const SizedBox(height: 8),
                Text(
                  t.app_settings.notifications_hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                SecuritySettingsEntryTile(onClose: onClose)
                    .animate()
                    .fadeIn(delay: 108.ms, duration: 260.ms)
                    .slideY(begin: 0.03),
                const SizedBox(height: 22),
                _SectionTitle(
                      icon: Icons.star_outline_rounded,
                      text: t.app_settings.section_about,
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 220.ms)
                    .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                const SizedBox(height: 10),
                _RateAppTile(
                      title: t.app_settings.rate_app,
                      subtitle: t.app_settings.rate_app_sub,
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        final ok =
                            await AppReviewService.instance.openStoreListing();
                        if (!context.mounted) return;
                        if (!ok) {
                          WayoToast.error(
                            context,
                            t.app_settings.rate_app_error,
                          );
                        }
                      },
                    )
                    .animate()
                    .fadeIn(delay: 110.ms, duration: 260.ms)
                    .slideY(begin: 0.03),
                const SizedBox(height: 22),
                _SectionTitle(
                      icon: Icons.manage_accounts_outlined,
                      text: t.app_settings.section_account,
                    )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 220.ms)
                    .slideX(begin: 0.04, curve: Curves.easeOutCubic),
                const SizedBox(height: 10),
                AccountDeletionSettingsSection(onClose: onClose)
                    .animate()
                    .fadeIn(delay: 140.ms, duration: 260.ms)
                    .slideY(begin: 0.03),
              ],
            ),
          ),
        ),
      ],
    );

    return _GlassLuxuryShell(child: core);
  }
}

class _GlassLuxuryShell extends StatelessWidget {
  const _GlassLuxuryShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
      child: ClipRRect(
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(28),
          bottomStart: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(28),
                bottomStart: Radius.circular(28),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.surfaceContainerHigh.withValues(
                    alpha: isDark ? 0.55 : 0.72,
                  ),
                  scheme.surface.withValues(alpha: isDark ? 0.42 : 0.88),
                ],
              ),
              border: Border.all(
                color: scheme.outlineVariant.withValues(
                  alpha: isDark ? 0.35 : 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 36,
                  offset: const Offset(-8, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _RateAppTile extends StatelessWidget {
  const _RateAppTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: scheme.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.onClose,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
  });

  final VoidCallback onClose;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;
    final subtle = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(avatarUrl: avatarUrl, label: displayName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.app_settings.title,
                  style: AppTextStyles.pageTitle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  t.app_settings.subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: subtle, height: 1.2),
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Semantics(
            button: true,
            label: t.app_settings.close_semantics,
            child: IconButton(
              tooltip: t.app_settings.close,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.label});

  final String? avatarUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = label.isNotEmpty
        ? String.fromCharCode(label.runes.first).toUpperCase()
        : '?';
    final raw = avatarUrl?.trim();
    final networkUrl = normalizeWayoAdsMediaUrl(raw);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primaryContainer,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: networkUrl != null
          ? CachedNetworkImage(
              key: ValueKey<String>(networkUrl),
              imageUrl: networkUrl,
              cacheKey: networkUrl,
              fit: BoxFit.cover,
              placeholder: (BuildContext context, String _) => Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              errorWidget: (BuildContext context, String _, Object error) =>
                  Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
            )
          : Center(
              child: Text(
                letter,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}

class _SegmentedThemeLabel extends StatelessWidget {
  const _SegmentedThemeLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.1);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: t.app_settings.section_appearance,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: SegmentedButton<ThemeMode>(
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              minimumSize: WidgetStateProperty.all(const Size(44, 44)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              ),
            ),
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: _SegmentedThemeLabel(text: t.app_settings.theme_light),
                icon: const Icon(Icons.light_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: _SegmentedThemeLabel(text: t.app_settings.theme_dark),
                icon: const Icon(Icons.dark_mode_outlined, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: _SegmentedThemeLabel(text: t.app_settings.theme_system),
                icon: const Icon(Icons.brightness_auto_outlined, size: 16),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) => onThemeChanged(s.first),
          ),
        ),
      ),
    );
  }
}

class _LanguageColumn extends StatelessWidget {
  const _LanguageColumn({required this.selected, required this.onSelect});

  final AppLocale selected;
  final ValueChanged<AppLocale> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final options = <({AppLocale locale, String label, String scriptHint})>[
      (locale: AppLocale.en, label: t.app_settings.lang_en, scriptHint: 'Aa'),
      (locale: AppLocale.fr, label: t.app_settings.lang_fr, scriptHint: 'Àà'),
      (locale: AppLocale.ar, label: t.app_settings.lang_ar, scriptHint: 'ع'),
    ];

    return Column(
      children: [
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == options.length - 1 ? 0 : 10),
            child: _LanguageTile(
              label: options[i].label,
              scriptHint: options[i].scriptHint,
              selected: selected == options[i].locale,
              onTap: () => onSelect(options[i].locale),
            ),
          ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.scriptHint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String scriptHint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      hint: selected ? t.app_settings.selected : null,
      child: Material(
        color: scheme.surface.withValues(alpha: selected ? 0.5 : 0.28),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(
                      alpha: selected ? 1 : 0.55,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    scriptHint,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: IgnorePointer(
                    ignoring: !selected,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
