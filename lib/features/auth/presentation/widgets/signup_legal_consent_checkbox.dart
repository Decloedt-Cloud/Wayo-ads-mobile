import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';

/// Required legal acceptance on signup — mirrors the web register form checkbox.
class SignupLegalConsentCheckbox extends StatefulWidget {
  const SignupLegalConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showError;

  @override
  State<SignupLegalConsentCheckbox> createState() =>
      _SignupLegalConsentCheckboxState();
}

class _SignupLegalConsentCheckboxState extends State<SignupLegalConsentCheckbox> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _cookiesTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = () => context.push('/terms');
    _privacyTap = TapGestureRecognizer()..onTap = () => context.push('/privacy');
    _cookiesTap =
        TapGestureRecognizer()..onTap = () => context.push('/cookie-policy');
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _cookiesTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final borderColor = widget.showError
        ? AppColors.error
        : AppColors.borderOf(context);
    final linkStyle = AppTextStyles.bodyLarge(context).copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 1.45,
    );
    final bodyStyle = AppTextStyles.bodyLarge(context).copyWith(
      fontSize: 14,
      height: 1.45,
      color: AppColors.textPrimaryOf(context),
    );

    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onChanged == null
            ? null
            : () => widget.onChanged!(!widget.value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: widget.showError ? 1.6 : 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: widget.value,
                        onChanged: widget.onChanged == null
                            ? null
                            : (v) => widget.onChanged!(v ?? false),
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return Colors.transparent;
                        }),
                        checkColor: Colors.white,
                        side: BorderSide(color: borderColor, width: 1.6),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.standard,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: bodyStyle,
                        children: [
                          TextSpan(text: t.signup.legal_prefix),
                          TextSpan(
                            text: t.signup.terms_of_service,
                            style: linkStyle,
                            recognizer: _termsTap,
                          ),
                          TextSpan(text: t.signup.legal_comma),
                          TextSpan(
                            text: t.signup.privacy_policy,
                            style: linkStyle,
                            recognizer: _privacyTap,
                          ),
                          TextSpan(text: t.signup.legal_and),
                          TextSpan(
                            text: t.signup.cookie_policy,
                            style: linkStyle,
                            recognizer: _cookiesTap,
                          ),
                          TextSpan(text: t.signup.legal_dot),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.showError) ...[
                const SizedBox(height: 8),
                Text(
                  t.signup.legal_required,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
