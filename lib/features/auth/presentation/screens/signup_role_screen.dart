import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../i18n/strings.g.dart';

class SignupRoleScreen extends StatefulWidget {
  const SignupRoleScreen({super.key});

  @override
  State<SignupRoleScreen> createState() => _SignupRoleScreenState();
}

class _SignupRoleScreenState extends State<SignupRoleScreen>
    with TickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _orange = Color(0xFFF97316);
  static const _dark = Color(0xFF18181B);

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

  void _continueWithRole(String role) {
    if (_selectedRole != null) return;
    setState(() => _selectedRole = role);
    context.go('/signup/register?role=$role');
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
                const SizedBox(height: 24),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                _buildHeader(isDark, t),
                const SizedBox(height: 40),
                Expanded(
                  child: Column(
                    children: [
                      _RoleCard(
                        icon: Icons.videocam_rounded,
                        title: t.onboarding.role_creator_cta,
                        description: t.onboarding.role_creator_desc,
                        isSelected: _selectedRole == 'CREATOR',
                        isLoading: _selectedRole == 'CREATOR',
                        isDark: isDark,
                        onTap: _selectedRole == null
                            ? () => _continueWithRole('CREATOR')
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        icon: Icons.campaign_rounded,
                        title: t.onboarding.role_advertiser_cta,
                        description: t.onboarding.role_advertiser_desc,
                        isSelected: _selectedRole == 'ADVERTISER',
                        isLoading: _selectedRole == 'ADVERTISER',
                        isDark: isDark,
                        onTap: _selectedRole == null
                            ? () => _continueWithRole('ADVERTISER')
                            : null,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(t.signup.already_have_account),
                ),
                const SizedBox(height: 16),
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
          ),
          child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          t.signup.role_title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : _dark,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t.signup.role_subtitle,
          style: TextStyle(
            fontSize: 16,
            height: 1.45,
            color: isDark ? Colors.white70 : Colors.black54,
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
  static const _darkCard = Color(0xFF27272A);
  static const _darkBorder = Color(0xFF3F3F46);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? _darkCard : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? _orange
                  : (isDark ? _darkBorder : const Color(0xFFE4E4E7)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
