import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../i18n/strings.g.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;

    return PopupMenuButton<AppLocale>(
      tooltip: t.common.language,
      offset: const Offset(0, 52),
      color: isDark ? const Color(0xFF161616) : Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      onSelected: (locale) {
        HapticFeedback.selectionClick();
        ref.read(localeProvider.notifier).set(locale);
      },
      itemBuilder: (_) => [
        _item(AppLocale.en, 'GB', 'English', current),
        _item(AppLocale.fr, 'FR', 'Français', current),
        _item(AppLocale.ar, 'AE', 'العربية', current),
      ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CountryFlag.fromCountryCode(
            _flagFor(current),
            height: 18,
            width: 24,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<AppLocale> _item(
    AppLocale locale,
    String countryCode,
    String label,
    AppLocale current,
  ) {
    final selected = locale == current;
    return PopupMenuItem<AppLocale>(
      value: locale,
      height: 48,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CountryFlag.fromCountryCode(
              countryCode,
              height: 20,
              width: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : null,
              ),
            ),
          ),
          if (selected)
            const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }

  String _flagFor(AppLocale locale) => switch (locale) {
        AppLocale.en => 'GB',
        AppLocale.fr => 'FR',
        AppLocale.ar => 'AE',
      };
}
