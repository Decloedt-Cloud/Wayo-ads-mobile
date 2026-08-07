import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/presentation/widgets/error_banner.dart';
import '../../data/advertiser_creators_remote.dart';

/// Browse creators approved on the advertiser's campaigns.
class AdvertiserCreatorsScreen extends ConsumerStatefulWidget {
  const AdvertiserCreatorsScreen({super.key});

  @override
  ConsumerState<AdvertiserCreatorsScreen> createState() =>
      _AdvertiserCreatorsScreenState();
}

class _AdvertiserCreatorsScreenState
    extends ConsumerState<AdvertiserCreatorsScreen> {
  final _search = TextEditingController();
  var _page = 1;
  var _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  AdvertiserCreatorsKey get _key => (page: _page, q: _q);

  @override
  Widget build(BuildContext context) {
    final t = context.t.advertiser_creators;
    final async = ref.watch(advertiserCreatorsProvider(_key));

    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      appBar: AppBar(
        title: Text(t.title, style: AppTextStyles.headlineMedium(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: t.search_hint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                setState(() {
                  _q = v.trim();
                  _page = 1;
                });
              },
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ErrorBanner(
                    message: t.load_error,
                    onRetry: () =>
                        ref.invalidate(advertiserCreatorsProvider(_key)),
                  ),
                ],
              ),
              data: (page) {
                if (page.creators.isEmpty) {
                  return Center(child: Text(t.empty));
                }
                return RefreshIndicator.adaptive(
                  onRefresh: () async {
                    ref.invalidate(advertiserCreatorsProvider(_key));
                    await ref.read(advertiserCreatorsProvider(_key).future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: page.creators.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == page.creators.length) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: _page > 1
                                  ? () => setState(() => _page--)
                                  : null,
                              child: Text(t.prev),
                            ),
                            Text('${page.page}/${page.totalPages}'),
                            TextButton(
                              onPressed: _page < page.totalPages
                                  ? () => setState(() => _page++)
                                  : null,
                              child: Text(t.next),
                            ),
                          ],
                        );
                      }
                      final row = page.creators[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage:
                              row.image != null && row.image!.isNotEmpty
                              ? NetworkImage(row.image!)
                              : null,
                          child: row.image == null || row.image!.isEmpty
                              ? Text(
                                  row.name.isNotEmpty
                                      ? row.name[0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        title: Text(row.name),
                        subtitle: Text(
                          [
                            if (row.trustScore != null)
                              t.trust(score: row.trustScore!),
                            '${row.views} views · ${row.clicks} clicks',
                            if (row.campaigns.isNotEmpty)
                              row.campaigns.take(2).join(' · '),
                          ].join('\n'),
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
