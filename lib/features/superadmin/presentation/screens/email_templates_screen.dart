import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_scaffold.dart';

/// Email template catalog + plaintext preview —
/// `GET /api/admin/emails/templates` and `…/preview/[template]`.
class EmailTemplatesScreen extends ConsumerWidget {
  const EmailTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(emailTemplatesProvider);

    return SuperadminScaffold(
      title: 'Email templates',
      onRefresh: () => ref.invalidate(emailTemplatesProvider),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(emailTemplatesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(child: Text('No templates'));
          }
          final grouped = <String, List<AdminEmailTemplate>>{};
          for (final t in templates) {
            grouped.putIfAbsent(t.category, () => []).add(t);
          }
          final categories = grouped.keys.toList()..sort();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(emailTemplatesProvider);
              await ref.read(emailTemplatesProvider.future);
            },
            child: ListView.builder(
              padding: superadminPagePadding(context),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final items = grouped[cat]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 0 : 16, bottom: 8),
                      child: Text(
                        cat.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ),
                    ...items.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TemplateCard(template: t),
                        )),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final AdminEmailTemplate template;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          showSuperadminSheet<void>(
            context: context,
            builder: (_) => _PreviewSheet(name: template.name),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template.subject,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              if (template.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedOf(context),
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

class _PreviewSheet extends ConsumerStatefulWidget {
  const _PreviewSheet({required this.name});

  final String name;

  @override
  ConsumerState<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends ConsumerState<_PreviewSheet> {
  var _sending = false;

  Future<void> _sendTest() async {
    final controller = TextEditingController();
    final to = await showWayoDialog<String>(
      context: context,
      builder: (ctx) => WayoAlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Send test email'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'you@example.com',
            filled: true,
            fillColor: AppColors.surfaceElevatedOf(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(14),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    final email = to?.trim() ?? '';
    if (email.isEmpty || !email.contains('@') || !mounted) return;

    setState(() => _sending = true);
    try {
      final result = await ref
          .read(superadminOpsRemoteProvider)
          .sendTestEmailTemplate(to: email, templateName: widget.name);
      if (!mounted) return;
      if (result.success) {
        WayoToast.success(context, result.message);
      } else {
        WayoToast.error(context, result.message);
      }
    } catch (e) {
      if (mounted) WayoToast.error(context, 'Send failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    final async = ref.watch(emailTemplatePreviewProvider(name));
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderOf(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Send test',
                  onPressed: _sending ? null : _sendTest,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
                IconButton(
                  onPressed: () =>
                      ref.invalidate(emailTemplatePreviewProvider(name)),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$e', textAlign: TextAlign.center),
              ),
              data: (preview) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.subject,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    if (preview.previewText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Preview text',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview.previewText,
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Plaintext body',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedOf(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        preview.text.isEmpty ? '(empty)' : preview.text,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textPrimaryOf(context),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Full HTML preview remains on web — use "Send test" above to '
                      'receive the rendered email.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
