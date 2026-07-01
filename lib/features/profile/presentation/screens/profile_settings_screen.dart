import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_system_nav_bar.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../router/app_router.dart';
import '../../../auth/presentation/providers/current_account_providers.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../data/user_profile_remote_datasource.dart';
import '../../domain/profile_name_errors.dart';
import '../../domain/wayo_ads_user_profile.dart';
import '../providers/user_profile_providers.dart';

const _kMaxAvatarBytes = 500 * 1024;
final _kProfilePlaceholderDate = DateTime.utc(1970);

Future<void> openProfileSettingsScreen({VoidCallback? onClosePanel}) async {
  onClosePanel?.call();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = rootNavigatorKey.currentContext;
    if (nav != null && nav.mounted) {
      GoRouter.of(nav).push('/settings/profile');
    }
  });
}

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen>
    with WidgetsBindingObserver {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  String? _pendingImageBase64;
  bool _removeImage = false;
  bool _saving = false;
  String? _nameError;
  bool _dirty = false;
  Timer? _remoteSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameController.addListener(_onFormChanged);
    _seedNameFromAuth(ref.read(currentAppUserProvider));
    ref.listenManual(userProfileProvider, (prev, next) {
      next.whenData(_applyProfileToForm);
    });
    ref.listenManual(currentAppUserProvider, (prev, next) {
      _seedNameFromAuth(next);
      if (!_dirty && mounted) {
        setState(() {
          _pendingImageBase64 = null;
          _removeImage = false;
        });
      }
    });
    _remoteSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || _dirty || _saving) return;
      unawaited(ref.read(userProfileProvider.notifier).syncRemoteAndAuth());
    });
  }

  void _seedNameFromAuth(AppUser? user) {
    if (_dirty) return;
    final n = user?.name?.trim();
    if (n == null || n.isEmpty) return;
    if (_nameController.text.trim() != n) {
      _nameController.text = n;
    }
  }

  WayoAdsUserProfile _profileForUi(
    AsyncValue<WayoAdsUserProfile> async,
    AppUser? authUser,
  ) {
    final remote = async.valueOrNull;
    if (remote != null && !remote.isPlaceholder) return remote;
    if (authUser != null) return WayoAdsUserProfile.fromAuthSession(authUser);
    if (remote != null) return remote;
    return WayoAdsUserProfile(
      id: '',
      email: '',
      roles: '',
      createdAt: _kProfilePlaceholderDate,
    );
  }

  bool _profileDetailsLoading(AsyncValue<WayoAdsUserProfile> async) {
    final remote = async.valueOrNull;
    return async.isLoading || remote == null || remote.isPlaceholder;
  }

  void _onFormChanged() {
    if (!_dirty) setState(() => _dirty = true);
    if (_nameError != null) setState(() => _nameError = null);
  }

  void _applyProfileToForm(WayoAdsUserProfile profile) {
    if (!_dirty) {
      _nameController.text = profile.name?.trim() ?? '';
      _pendingImageBase64 = null;
      _removeImage = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_dirty && !_saving) {
      unawaited(
        ref.read(userProfileProvider.notifier).syncRemoteAndAuth(
              refreshAuth: true,
            ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _remoteSyncTimer?.cancel();
    _nameController.removeListener(_onFormChanged);
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  String? _resolveAvatarUrl(WayoAdsUserProfile profile) {
    if (_removeImage) return null;
    if (_pendingImageBase64 != null) return _pendingImageBase64;
    final fromProfile = normalizeWayoAdsMediaUrl(profile.image);
    if (fromProfile != null) return fromProfile;
    final authAvatar = ref.read(currentAppUserProvider)?.avatar?.trim();
    if (authAvatar != null && authAvatar.isNotEmpty) return authAvatar;
    return null;
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return;
      if (bytes.length > _kMaxAvatarBytes) {
        if (mounted) {
          WayoToast.error(context, context.t.profile.avatar_too_large);
        }
        return;
      }
      final ext = (file.extension ?? 'jpg').toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      setState(() {
        _pendingImageBase64 = 'data:$mime;base64,${base64Encode(bytes)}';
        _removeImage = false;
        _dirty = true;
      });
    } catch (_) {
      if (mounted) {
        WayoToast.error(context, context.t.profile.avatar_pick_error);
      }
    }
  }

  void _removeAvatar() {
    HapticFeedback.selectionClick();
    setState(() {
      _pendingImageBase64 = null;
      _removeImage = true;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final t = context.t.profile;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = t.display_name_required);
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
    });
    HapticFeedback.mediumImpact();
    try {
      await ref.read(userProfileProvider.notifier).save(
            name: name,
            imageBase64: _pendingImageBase64,
            removeImage: _removeImage,
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
        _pendingImageBase64 = null;
        _removeImage = false;
      });
      ref.invalidate(dashboardStreamProvider);
      WayoToast.success(context, t.saved);
    } on UserProfileUpdateException catch (e) {
      if (!mounted) return;
      final code = profileNameErrorCode(e);
      final msg = switch (code) {
        'name_taken' => t.name_taken,
        'name_invalid' => t.name_invalid,
        _ => e.message.isNotEmpty ? e.message : t.save_error,
      };
      final fieldError = isProfileNameFieldError(code) ? msg : null;
      setState(() {
        _saving = false;
        _nameError = fieldError;
      });
      if (fieldError != null) {
        _nameFocus.requestFocus();
      }
      WayoToast.error(context, msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      WayoToast.error(context, t.save_error);
    }
  }

  Future<void> _refresh() async {
    await ref.read(userProfileProvider.notifier).syncRemoteAndAuth(
          refreshAuth: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.profile;
    final asyncProfile = ref.watch(userProfileProvider);
    final authUser = ref.watch(currentAppUserProvider);
    final scheme = Theme.of(context).colorScheme;
    final displayProfile = _profileForUi(asyncProfile, authUser);
    final detailsLoading = _profileDetailsLoading(asyncProfile);

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
                  if (asyncProfile.hasError && asyncProfile.valueOrNull == null)
                    _ErrorCard(
                      message: t.load_error,
                      onRetry: () => ref.invalidate(userProfileProvider),
                    )
                  else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileInfoCard(
                          profile: displayProfile,
                          avatarUrl: _resolveAvatarUrl(displayProfile),
                          nameController: _nameController,
                          nameFocus: _nameFocus,
                          nameError: _nameError,
                          saving: _saving,
                          onPickImage: _pickImage,
                          onRemoveImage: _removeAvatar,
                          onSave: _save,
                          canRemoveImage:
                              _pendingImageBase64 != null ||
                              (displayProfile.image?.isNotEmpty == true &&
                                  !_removeImage),
                        )
                            .animate()
                            .fadeIn(duration: 280.ms)
                            .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                        const SizedBox(height: 16),
                        _AccountDetailsCard(
                          profile: displayProfile,
                          detailsLoading: detailsLoading,
                        )
                            .animate()
                            .fadeIn(delay: 60.ms, duration: 280.ms)
                            .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                      ],
                    ),
                    if (asyncProfile.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                  ],
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

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.profile,
    required this.avatarUrl,
    required this.nameController,
    required this.nameFocus,
    required this.nameError,
    required this.saving,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onSave,
    required this.canRemoveImage,
  });

  final WayoAdsUserProfile profile;
  final String? avatarUrl;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final String? nameError;
  final bool saving;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onSave;
  final bool canRemoveImage;

  @override
  Widget build(BuildContext context) {
    final t = context.t.profile;
    final scheme = Theme.of(context).colorScheme;
    final displayName = nameController.text.trim().isNotEmpty
        ? nameController.text.trim()
        : (profile.name ?? profile.email);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, color: scheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.section_info_title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.section_info_desc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: _AvatarEditor(
              label: displayName,
              avatarUrl: avatarUrl,
              onTap: onPickImage,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.avatar_hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: saving ? null : onPickImage,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(t.avatar_upload),
              ),
              if (canRemoveImage) ...[
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: saving ? null : onRemoveImage,
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  label: Text(
                    t.avatar_remove,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Text(
            t.display_name,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            focusNode: nameFocus,
            enabled: !saving,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSave(),
            decoration: InputDecoration(
              hintText: t.display_name_hint,
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: nameError != null
                      ? scheme.error
                      : scheme.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: nameError != null
                      ? scheme.error
                      : scheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: nameError != null ? scheme.error : scheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (nameError != null) ...[
            const SizedBox(height: 8),
            Text(
              nameError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
          const SizedBox(height: 20),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: saving
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
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
                        Text(t.saving),
                      ],
                    )
                  : Text(t.save_changes),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard({
    required this.profile,
    this.detailsLoading = false,
  });

  final WayoAdsUserProfile profile;
  final bool detailsLoading;

  @override
  Widget build(BuildContext context) {
    final t = context.t.profile;
    final scheme = Theme.of(context).colorScheme;
    final loc = Localizations.localeOf(context).toString();
    final memberSince = profile.isPlaceholder || detailsLoading
        ? '…'
        : DateFormat.yMMMMd(loc).format(profile.createdAt);
    final rolesLabel = formatProfileRoles(
      profile.roles,
      creatorLabel: t.role_creator,
      advertiserLabel: t.role_advertiser,
      userLabel: t.role_user,
    );

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: scheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.section_details_title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.section_details_desc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.mail_outline_rounded,
            label: t.email,
            value: profile.email,
          ),
          _DetailRow(
            icon: Icons.badge_outlined,
            label: t.roles,
            value: rolesLabel,
          ),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: t.member_since,
            value: memberSince,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ],
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.label,
    required this.avatarUrl,
    required this.onTap,
  });

  final String label;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = label.isNotEmpty
        ? String.fromCharCode(label.runes.first).toUpperCase()
        : '?';
    final raw = avatarUrl?.trim();

    Widget avatarChild;
    if (raw != null && raw.startsWith('data:')) {
      avatarChild = Image.memory(
        base64Decode(raw.split(',').last),
        fit: BoxFit.cover,
        width: 112,
        height: 112,
      );
    } else if (raw != null && raw.isNotEmpty) {
      avatarChild = CachedNetworkImage(
        imageUrl: raw,
        fit: BoxFit.cover,
        width: 112,
        height: 112,
        placeholder: (_, __) => _letter(letter, scheme),
        errorWidget: (_, __, ___) => _letter(letter, scheme),
      );
    } else {
      avatarChild = _letter(letter, scheme);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
              ),
              child: ClipOval(child: avatarChild),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _letter(String letter, ColorScheme scheme) {
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.t.dashboard.errors.retry),
          ),
        ],
      ),
    );
  }
}
