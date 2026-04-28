import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_error_localizer.dart';
import '../../../../core/result.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/onboarding_gate.dart';

class WayoAdsRoleOnboardingScreen extends ConsumerStatefulWidget {
  const WayoAdsRoleOnboardingScreen({super.key});

  @override
  ConsumerState<WayoAdsRoleOnboardingScreen> createState() =>
      _WayoAdsRoleOnboardingScreenState();
}

class _WayoAdsRoleOnboardingScreenState
    extends ConsumerState<WayoAdsRoleOnboardingScreen>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  String? _selectedRole;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _orange = Color(0xFFF97316);
  static const _orangeLight = Color(0xFFFFEDD5);
  static const _dark = Color(0xFF18181B);
  static const _darkCard = Color(0xFF27272A);
  static const _darkBorder = Color(0xFF3F3F46);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pick(String role) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _selectedRole = role;
    });
    final t = context.t;
    final repo = ref.read(authRepositoryProvider);
    final r = await repo.setWayoAdsAppRole(role);
    if (!mounted) return;
    switch (r) {
      case Success(:final data):
        await ref.read(authNotifierProvider.notifier).applyOnboardingUser(data);
        if (!mounted) return;
        final next = onboardingRedirectPath(data);
        context.go(next ?? '/dashboard');
      case Failure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizeAuthError(error, t)),
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _selectedRole = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _dark : Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildHeader(isDark, t),
                const SizedBox(height: 48),
                Expanded(
                  child: Column(
                    children: [
                      _RoleCard(
                        icon: Icons.videocam_rounded,
                        title: t.onboarding.role_creator_cta,
                        description: t.onboarding.role_creator_desc,
                        isSelected: _selectedRole == 'CREATOR',
                        isLoading: _busy && _selectedRole == 'CREATOR',
                        isDark: isDark,
                        onTap: _busy ? null : () => _pick('CREATOR'),
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        icon: Icons.campaign_rounded,
                        title: t.onboarding.role_advertiser_cta,
                        description: t.onboarding.role_advertiser_desc,
                        isSelected: _selectedRole == 'ADVERTISER',
                        isLoading: _busy && _selectedRole == 'ADVERTISER',
                        isDark: isDark,
                        onTap: _busy ? null : () => _pick('ADVERTISER'),
                      ),
                    ],
                  ),
                ),
                _buildFooter(isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Translations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_orange, Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _orange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t.onboarding.role_gate_title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : _dark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.onboarding.role_gate_subtitle,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
        const SizedBox(width: 6),
        Text(
          'You can change this later in settings',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.isLoading,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final bool isLoading;
  final bool isDark;
  final VoidCallback? onTap;

  static const _orange = Color(0xFFF97316);
  static const _orangeLight = Color(0xFFFFEDD5);
  static const _darkCard = Color(0xFF27272A);
  static const _darkBorder = Color(0xFF3F3F46);

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? _orange
        : (isDark ? _darkBorder : Colors.grey[200]!);
    final bgColor = isSelected
        ? (isDark ? _orange.withOpacity(0.1) : _orangeLight.withOpacity(0.5))
        : (isDark ? _darkCard : Colors.grey[50]);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _orange.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _orange
                        : (isDark ? const Color(0xFF3F3F46) : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          icon,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          size: 26,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: _orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
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
