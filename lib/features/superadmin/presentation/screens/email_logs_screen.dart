import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../../domain/entities/admin_ops.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// Outbound email delivery log — `GET /api/admin/emails/logs`.
class EmailLogsScreen extends ConsumerWidget {
  const EmailLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(emailLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Email logs'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(emailLogsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SuperadminChromeActions(trailingPadding: 12),
        ],
      ),
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
                  onPressed: () => ref.invalidate(emailLogsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (page) {
          if (page.logs.isEmpty) {
            return const Center(child: Text('No email logs'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(emailLogsProvider);
              await ref.read(emailLogsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: page.logs.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == page.logs.length) {
                  return Text(
                    '${page.total} total',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMutedOf(context),
                      fontSize: 12,
                    ),
                  );
                }
                return _LogCard(log: page.logs[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});
  final EmailLogRecord log;

  @override
  Widget build(BuildContext context) {
    final ok = log.status.toUpperCase() == 'SENT' ||
        log.status.toUpperCase() == 'DELIVERED' ||
        log.status.toUpperCase() == 'SUCCESS';
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.subject.isEmpty ? '(no subject)' : log.subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (ok ? const Color(0xFF22C55E) : AppColors.error)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    log.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ok ? const Color(0xFF22C55E) : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              log.toName?.trim().isNotEmpty == true
                  ? '${log.toName} · ${log.toEmail}'
                  : log.toEmail,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),
            if (log.templateName != null && log.templateName!.isNotEmpty)
              Text(
                'Template: ${log.templateName}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            if (log.errorMessage != null && log.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                log.errorMessage!,
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              DateFormat.yMMMd().add_Hm().format(log.sentAt.toLocal()),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
