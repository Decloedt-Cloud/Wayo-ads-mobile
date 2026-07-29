import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official-style Google Pay CTA: "Pay with" + colorful G + "Pay".
enum GooglePayButtonStyle { dark, light }

class GooglePayButton extends StatelessWidget {
  const GooglePayButton({
    super.key,
    required this.onPressed,
    required this.payWithPrefix,
    this.busy = false,
    this.disabled = false,
    this.style = GooglePayButtonStyle.dark,
    this.height = 48,
  });

  final VoidCallback? onPressed;
  final String payWithPrefix;
  final bool busy;
  final bool disabled;
  final GooglePayButtonStyle style;
  final double height;

  static const _gLogoAsset = 'assets/branding/google_g_logo.svg';

  @override
  Widget build(BuildContext context) {
    final isDarkStyle = style == GooglePayButtonStyle.dark;
    final foreground = isDarkStyle ? Colors.white : const Color(0xFF3C4043);
    final background = isDarkStyle ? Colors.black : Colors.white;
    final radius = BorderRadius.circular(height / 2);
    final enabled = !disabled && !busy && onPressed != null;

    final labelStyle = TextStyle(
      color: foreground.withValues(alpha: enabled ? 1 : 0.45),
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1,
      letterSpacing: 0.15,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: '$payWithPrefix G Pay',
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Material(
          color: background.withValues(alpha: enabled ? 1 : 0.55),
          elevation: 0,
          borderRadius: radius,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: background.withValues(alpha: enabled ? 1 : 0.55),
                border: isDarkStyle
                    ? null
                    : Border.all(
                        color: foreground.withValues(alpha: enabled ? 1 : 0.35),
                      ),
              ),
              child: Center(
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(payWithPrefix, style: labelStyle),
                          const SizedBox(width: 6),
                          SvgPicture.asset(
                            _gLogoAsset,
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 2),
                          Text('Pay', style: labelStyle),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
