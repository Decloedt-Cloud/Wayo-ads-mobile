import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/superadmin_ops_remote.dart';
import '../widgets/superadmin_chrome_actions.dart';

/// In-app notification broadcast — `POST /api/admin/notifications/broadcast`.
class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  var _scope = 'GLOBAL';
  var _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final message = _message.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(superadminOpsRemoteProvider).sendBroadcast(
            title: title,
            message: message,
            scope: _scope == 'GLOBAL' ? 'GLOBAL' : 'ROLE',
            toRole: _scope == 'GLOBAL' ? null : _scope,
          );
      if (!mounted) return;
      _title.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: const Text('Broadcast'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: const [SuperadminChromeActions(trailingPadding: 12)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Send an in-app notification to everyone or a role.',
            style: TextStyle(color: AppColors.textMutedOf(context)),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'GLOBAL', label: Text('All')),
              ButtonSegment(value: 'CREATOR', label: Text('Creators')),
              ButtonSegment(value: 'ADVERTISER', label: Text('Ads')),
            ],
            selected: {_scope},
            onSelectionChanged: (s) => setState(() => _scope = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.campaign_rounded),
            label: Text(_sending ? 'Sending…' : 'Send broadcast'),
          ),
        ],
      ),
    );
  }
}
