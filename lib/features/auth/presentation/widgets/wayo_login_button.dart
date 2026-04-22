import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WayoLoginButton extends StatefulWidget {
  const WayoLoginButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.enabled = true,
    this.label = 'Se connecter',
  });

  final VoidCallback onPressed;
  final bool isLoading;

  /// When false, the button is non-interactive and shows no loading spinner (unless [isLoading]).
  final bool enabled;
  final String label;

  @override
  State<WayoLoginButton> createState() => _WayoLoginButtonState();
}

class _WayoLoginButtonState extends State<WayoLoginButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final visuallyBusy = widget.isLoading;
    final tapDisabled = widget.isLoading || !widget.enabled;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final arrowIcon = rtl
        ? Icons.arrow_back_rounded
        : Icons.arrow_forward_rounded;

    return Semantics(
      button: true,
      enabled: !tapDisabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: tapDisabled
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onPressed();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 58,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: isDark
                        ? (_pressed ? 0.25 : 0.45)
                        : (_pressed ? 0.16 : 0.28),
                  ),
                  blurRadius: _pressed ? 16 : (isDark ? 28 : 22),
                  spreadRadius: isDark ? -6 : -4,
                  offset: Offset(0, isDark ? 12 : 8),
                ),
              ],
            ),
            foregroundDecoration: (!widget.enabled && !widget.isLoading)
                ? BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                  )
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!visuallyBusy)
                    const Positioned.fill(child: _ShimmerSweep()),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: visuallyBusy
                        ? const SizedBox(
                            key: ValueKey('loader'),
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            key: const ValueKey('label'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.label,
                                style: AppTextStyles.labelLarge(
                                  context,
                                ).copyWith(color: Colors.white, fontSize: 16),
                              ),
                              const SizedBox(width: 10),
                              Icon(arrowIcon, color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerSweep extends StatelessWidget {
  const _ShimmerSweep();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child:
          DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0.3, 0.5, 0.7],
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 2200.ms,
                color: Colors.white.withValues(alpha: 0.15),
              ),
    );
  }
}
