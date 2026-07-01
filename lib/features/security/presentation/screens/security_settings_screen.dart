import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_system_nav_bar.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../router/app_router.dart';
import '../../../auth/presentation/widgets/password_strength_indicator.dart';
import '../../../app_settings/presentation/providers/active_sessions_providers.dart';
import '../../../profile/domain/wayo_ads_user_profile.dart';
import '../../../profile/presentation/providers/user_profile_providers.dart';
import '../../data/change_password_remote.dart';
import '../providers/security_providers.dart';
import '../widgets/security_active_sessions_section.dart';

Future<void> openSecuritySettingsScreen({VoidCallback? onClosePanel}) async {
  onClosePanel?.call();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = rootNavigatorKey.currentContext;
    if (nav != null && nav.mounted) {
      GoRouter.of(nav).push('/settings/security');
    }
  });
}

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _isOAuthOnly(AsyncValue<WayoAdsUserProfile> profileAsync) {
    final p = profileAsync.valueOrNull;
    if (p == null) return false;
    return p.deletionRequiresPassword == false;
  }

  String? _validateNewPassword(String? v, Translations t) {
    final s = v ?? '';
    if (s.isEmpty) return t.validation.required;
    if (s.length < 8) return t.validation.min8;
    if (!RegExp(r'[A-Z]').hasMatch(s)) return t.validation.need_upper;
    if (!RegExp(r'[0-9]').hasMatch(s)) return t.validation.need_digit;
    return null;
  }

  Future<void> _submitPassword() async {
    if (_saving) return;
    final t = context.t.security;
    final v = context.t.validation;

    setState(() => _formError = null);

    final current = _currentCtrl.text;
    final newPwd = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
      setState(() => _formError = t.all_fields_required);
      return;
    }
    if (newPwd.length < 8) {
      setState(() => _formError = t.password_min_length);
      return;
    }
    if (newPwd == current) {
      setState(() => _formError = t.password_same_as_current);
      return;
    }
    if (newPwd != confirm) {
      setState(() => _formError = v.mismatch);
      return;
    }
    final ruleError = _validateNewPassword(newPwd, context.t);
    if (ruleError != null) {
      setState(() => _formError = ruleError);
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      await ref.read(changePasswordRemoteProvider).changePassword(
            currentPassword: current,
            newPassword: newPwd,
            confirmation: confirm,
          );
      if (!mounted) return;
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      setState(() => _saving = false);
      WayoToast.success(context, t.password_updated);
    } on ChangePasswordException catch (e) {
      if (!mounted) return;
      final sessionExpired = context.t.login.session_expired_snack;
      final lower = e.message.toLowerCase();
      final msg = switch (e.statusCode) {
        401 => sessionExpired,
        403 => lower.contains('oauth')
            ? t.password_oauth_message
            : t.password_wrong_current,
        422 => lower.contains('current password') ||
                lower.contains('mot de passe actuel')
            ? t.password_wrong_current
            : (e.message.isNotEmpty ? e.message : t.password_change_error),
        _ => lower == 'unauthorized' ? sessionExpired : (
            e.message.isNotEmpty ? e.message : t.password_change_error),
      };
      setState(() {
        _saving = false;
        _formError = msg;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = t.password_change_error;
      });
      WayoToast.error(context, t.password_change_error);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(activeSessionsProvider);
    await ref.read(userProfileProvider.notifier).syncRemoteAndAuth(
          refreshAuth: true,
        );
    await ref.read(activeSessionsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.security;
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(userProfileProvider);
    final oauthOnly = _isOAuthOnly(profileAsync);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: wayoSystemNavBarOverlay(context),
      child: Scaffold(
        backgroundColor: scheme.surface,
        bottomNavigationBar: const WayoSystemNavBarFill(),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 48,
                scrolledUnderElevation: 0,
                backgroundColor: scheme.surface.withValues(alpha: 0.92),
                surfaceTintColor: Colors.transparent,
                leadingWidth: 44,
                titleSpacing: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 22),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  t.nav_title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SecurityCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionHeader(
                            icon: oauthOnly
                                ? Icons.shield_outlined
                                : Icons.lock_outline_rounded,
                            title: oauthOnly
                                ? t.password_management_title
                                : t.change_password_title,
                          ),
                          const SizedBox(height: 18),
                          if (oauthOnly)
                            _OAuthPasswordBanner(message: t.password_oauth_message)
                          else ...[
                            if (_formError != null) ...[
                              _InlineError(message: _formError!),
                              const SizedBox(height: 12),
                            ],
                            _PasswordField(
                              controller: _currentCtrl,
                              label: t.current_password,
                              obscure: _obscureCurrent,
                              onToggleObscure: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _PasswordField(
                              controller: _newCtrl,
                              label: t.new_password,
                              obscure: _obscureNew,
                              onToggleObscure: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                            if (_newCtrl.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              PasswordStrengthIndicator(
                                password: _newCtrl.text,
                              ),
                            ],
                            const SizedBox(height: 14),
                            _PasswordField(
                              controller: _confirmCtrl,
                              label: t.confirm_password,
                              obscure: _obscureConfirm,
                              onToggleObscure: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _saving ? null : _submitPassword,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _saving
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(t.updating_password),
                                      ],
                                    )
                                  : Text(t.update_password),
                            ),
                          ],
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 280.ms)
                        .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                    const SizedBox(height: 16),
                    _SecurityCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionHeader(
                            icon: Icons.verified_user_outlined,
                            title: context.t.app_settings.sessions_title,
                            subtitle: context.t.app_settings.sessions_desc,
                          ),
                          const SizedBox(height: 16),
                          const SecurityActiveSessionsSection(),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 60.ms, duration: 280.ms)
                        .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final t = context.t.login;
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surface.withValues(alpha: 0.45),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        suffixIcon: IconButton(
          tooltip: obscure ? t.show_password : t.hide_password,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OAuthPasswordBanner extends StatelessWidget {
  const _OAuthPasswordBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const infoColor = Color(0xFF2563EB);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: infoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: infoColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: infoColor.withValues(alpha: 0.9), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: infoColor.withValues(alpha: 0.95),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
