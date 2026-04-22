import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';

class LoginFooter extends StatefulWidget {
  const LoginFooter({super.key});

  @override
  State<LoginFooter> createState() => _LoginFooterState();
}

class _LoginFooterState extends State<LoginFooter> {
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  void _openPrivacy() {
    context.push('/privacy');
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 14,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(width: 6),
            Text(t.login.secure_note, style: AppTextStyles.caption(context)),
          ],
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: AppTextStyles.caption(context),
            children: [
              TextSpan(text: t.login.terms_prefix),
              TextSpan(
                text: t.login.terms,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: t.login.and),
              TextSpan(
                text: t.login.privacy,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: _privacyTap,
              ),
              TextSpan(text: t.login.dot),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
