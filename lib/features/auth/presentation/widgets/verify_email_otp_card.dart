import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/widgets/language_switcher.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
import 'otp_input_field.dart';

/// Auth_Wayo `/email/verify` UI — card, OTP, Verify + Resend (web parity).
class VerifyEmailOtpCard extends StatelessWidget {
  const VerifyEmailOtpCard({
    super.key,
    required this.otpKey,
    required this.sending,
    required this.verifying,
    required this.cooldown,
    required this.showCodeSentBanner,
    required this.sendError,
    required this.code,
    required this.onCodeChanged,
    required this.onVerify,
    required this.onResend,
    required this.onDifferentAccount,
    this.headerExtra,
    this.showTopChrome = true,
  });

  final int otpKey;
  final bool sending;
  final bool verifying;
  final int cooldown;
  final bool showCodeSentBanner;
  final String? sendError;
  final String code;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onDifferentAccount;
  final Widget? headerExtra;
  final bool showTopChrome;

  @override
  Widget build(BuildContext context) {
    final t = context.t.verify;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busy = sending || verifying;
    final canVerify = code.length == 6 && !busy;
    final canResend = !busy && cooldown <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTopChrome)
          Row(
            children: const [
              Spacer(),
              LanguageSwitcher(),
              SizedBox(width: 4),
              ThemeToggleButton(),
            ],
          ),
        if (showTopChrome) const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3F3F46)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium(context).copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t.subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: AppColors.textSecondaryOf(context),
                  height: 1.45,
                  fontSize: 15,
                ),
              ),
              if (headerExtra != null) ...[
                const SizedBox(height: 16),
                headerExtra!,
              ],
              const SizedBox(height: 20),
              if (showCodeSentBanner) _CodeSentBanner(message: t.code_sent),
              if (sendError != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: sendError!),
              ],
              const SizedBox(height: 20),
              Text(
                t.code_label.toUpperCase(),
                style: AppTextStyles.caption(context).copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 14),
              if (sending)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IgnorePointer(
                  ignoring: busy,
                  child: Opacity(
                    opacity: busy ? 0.5 : 1,
                    child: OtpInputField(
                      key: ValueKey(otpKey),
                      grouped: true,
                      autoSubmit: false,
                      enabled: !busy,
                      onChanged: onCodeChanged,
                      onCompleted: (_) {},
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              _VerifyButton(
                label: t.verify_btn,
                loading: verifying,
                enabled: canVerify,
                onPressed: onVerify,
              ),
              const SizedBox(height: 20),
              _OrDivider(label: t.or_label),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: canResend ? onResend : null,
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: Text(
                  cooldown > 0 ? t.resend_in(seconds: cooldown) : t.resend,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.textPrimaryOf(context),
                  side: BorderSide(
                    color: AppColors.textMutedOf(context).withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.spam,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: busy ? null : onDifferentAccount,
          child: Text(
            t.different_account,
            style: AppTextStyles.labelLarge(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeSentBanner extends StatelessWidget {
  const _CodeSentBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 14,
                height: 1.35,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 14,
                height: 1.35,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = AppColors.textMutedOf(context).withValues(alpha: 0.35);
    return Row(
      children: [
        Expanded(child: Divider(color: line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textSecondaryOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: line, height: 1)),
      ],
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled || loading ? AppColors.primaryGradient : null,
          color: enabled || loading ? null : AppColors.textMutedOf(context).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled && !loading
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled && !loading ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: AppTextStyles.labelLarge(context).copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
