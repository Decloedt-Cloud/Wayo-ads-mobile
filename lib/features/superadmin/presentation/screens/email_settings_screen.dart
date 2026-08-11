import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_scaffold.dart';

/// SMTP / email settings — `GET|PUT /api/admin/email-settings` +
/// `POST /api/admin/email-settings/test-email`.
///
/// The server always re-encrypts and re-creates the settings row on save, so
/// the password field is required on every save (omitting it would silently
/// wipe the stored credential — same behavior as web).
class EmailSettingsScreen extends ConsumerStatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  ConsumerState<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends ConsumerState<EmailSettingsScreen> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '587');
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _fromEmail = TextEditingController();
  final _fromName = TextEditingController();
  final _replyTo = TextEditingController();
  final _testEmail = TextEditingController();

  var _secure = true;
  var _enabled = true;
  var _obscurePassword = true;
  var _hydrated = false;
  var _saving = false;
  var _testingSmtp = false;

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _fromEmail.dispose();
    _fromName.dispose();
    _replyTo.dispose();
    _testEmail.dispose();
    super.dispose();
  }

  void _hydrate(EmailSettingsSnapshot? s) {
    if (_hydrated || s == null) return;
    _hydrated = true;
    _host.text = s.host;
    _port.text = '${s.port}';
    _secure = s.secure;
    _fromEmail.text = s.fromEmail;
    _fromName.text = s.fromName ?? '';
    _replyTo.text = s.replyToEmail ?? '';
    _enabled = s.isEnabled;
  }

  Future<void> _save() async {
    if (_password.text.isEmpty) {
      WayoToast.warning(
        context,
        'Re-enter the SMTP password to save — the server always re-encrypts '
        'credentials on update, so an empty password wipes the stored one.',
      );
      return;
    }
    if (_host.text.trim().isEmpty || _fromEmail.text.trim().isEmpty) {
      WayoToast.warning(context, 'Host and from-email are required');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(superadminOpsRemoteProvider).updateEmailSettings(
            host: _host.text.trim(),
            port: int.tryParse(_port.text.trim()) ?? 587,
            secure: _secure,
            fromEmail: _fromEmail.text.trim(),
            isEnabled: _enabled,
            password: _password.text,
            username: _username.text.trim().isEmpty ? null : _username.text.trim(),
            fromName: _fromName.text.trim().isEmpty ? null : _fromName.text.trim(),
            replyToEmail: _replyTo.text.trim().isEmpty ? null : _replyTo.text.trim(),
          );
      _password.clear();
      ref.invalidate(emailSettingsProvider);
      if (mounted) WayoToast.success(context, 'Email settings saved');
    } catch (e) {
      if (mounted) WayoToast.error(context, 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendTest() async {
    final email = _testEmail.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      WayoToast.warning(context, 'Enter a valid email address');
      return;
    }
    setState(() => _testingSmtp = true);
    try {
      final result = await ref.read(superadminOpsRemoteProvider).testSmtpEmail(email: email);
      if (!mounted) return;
      if (result.success) {
        WayoToast.success(context, result.message);
      } else {
        WayoToast.error(context, result.message);
      }
    } catch (e) {
      if (mounted) WayoToast.error(context, 'Test email failed: $e');
    } finally {
      if (mounted) setState(() => _testingSmtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(emailSettingsProvider);

    return SuperadminScaffold(
      title: 'Email settings',
      onRefresh: () => ref.invalidate(emailSettingsProvider),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) {
          _hydrate(s);
          return ListView(
            padding: superadminPagePadding(context),
            children: [
              if (s != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (s.isEnabled ? AppColors.success : AppColors.textMuted)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s.isEnabled ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: s.isEnabled ? AppColors.success : AppColors.textMutedOf(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (s.updatedAt != null)
                        Expanded(
                          child: Text(
                            'Updated ${DateFormat.yMMMd().add_Hm().format(s.updatedAt!.toLocal())}'
                            '${s.updatedByEmail != null ? ' by ${s.updatedByEmail}' : ''}',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textMutedOf(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              SuperadminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enabled'),
                      subtitle: const Text('Turn SMTP sending on/off platform-wide'),
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _host,
                            decoration: const InputDecoration(labelText: 'SMTP host'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _port,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Port'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Secure (TLS/SSL)'),
                      value: _secure,
                      onChanged: (v) => setState(() => _secure = v),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _username,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: s?.usernameMasked != null ? 'Currently: ${s!.usernameMasked}' : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password (required to save)',
                        helperText: 'Always re-enter — saving re-encrypts all credentials',
                        helperMaxLines: 2,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fromEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'From email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fromName,
                      decoration: const InputDecoration(labelText: 'From name (optional)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _replyTo,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Reply-to email (optional)'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving…' : 'Save settings'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SuperadminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send test email',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimaryOf(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sends a plain SMTP test using the currently saved credentials.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _testEmail,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Test recipient',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _testingSmtp ? null : _sendTest,
                          icon: _testingSmtp
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          label: Text(_testingSmtp ? 'Sending…' : 'Send'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
