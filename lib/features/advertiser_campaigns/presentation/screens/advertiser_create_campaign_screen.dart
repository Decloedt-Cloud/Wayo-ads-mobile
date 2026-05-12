import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../data/advertiser_campaigns_repository.dart';
import '../../domain/advertiser_campaign_create_payload.dart';
import '../../domain/campaign_niche_catalog.dart';
import '../providers/advertiser_campaigns_providers.dart';

double? _parseMajorMoney(String raw) {
  final t = raw.trim().replaceAll(',', '.');
  if (t.isEmpty) {
    return null;
  }
  return double.tryParse(t);
}

bool _isHttpsUrl(String raw) {
  final u = Uri.tryParse(raw.trim());
  return u != null && u.isAbsolute && u.scheme == 'https';
}

/// Wayo-ads–aligned advertiser flow: LINK / VIDEO / SHORTS, niche, objective,
/// budgets as major currency units → cents (same as web `CampaignEditorForm`).
class AdvertiserCreateCampaignScreen extends ConsumerStatefulWidget {
  const AdvertiserCreateCampaignScreen({super.key});

  @override
  ConsumerState<AdvertiserCreateCampaignScreen> createState() =>
      _AdvertiserCreateCampaignScreenState();
}

class _AdvertiserCreateCampaignScreenState
    extends ConsumerState<AdvertiserCreateCampaignScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _landingCtrl = TextEditingController();
  final _assetsCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _cpmCtrl = TextEditingController();
  final _cpcCtrl = TextEditingController();

  String _typeApi = 'LINK';
  String _nicheApi = kCampaignNicheApiValues.last;
  String _objectiveApi = 'TRAFFIC';
  int _videoMinMinutes = 1;
  String _shortsPlatformApi = 'YOUTUBE';
  int _shortsMaxSeconds = 60;

  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _landingCtrl.dispose();
    _assetsCtrl.dispose();
    _budgetCtrl.dispose();
    _cpmCtrl.dispose();
    _cpcCtrl.dispose();
    super.dispose();
  }

  String? _validate(Translations t) {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      return t.advertiser_campaigns.create.validation_title;
    }

    final budget = _parseMajorMoney(_budgetCtrl.text);
    if (budget == null || budget <= 0) {
      return t.advertiser_campaigns.create.validation_title;
    }

    if (_typeApi == 'LINK') {
      if (!_isHttpsUrl(_landingCtrl.text)) {
        return t.advertiser_campaigns.create.validation_title;
      }
      final cpc = _parseMajorMoney(_cpcCtrl.text);
      if (cpc == null || cpc <= 0) {
        return t.advertiser_campaigns.create.validation_title;
      }
    } else {
      final assets = _assetsCtrl.text.trim();
      if (!isCampaignAssetsSharingUrlValid(assets)) {
        return t.advertiser_campaigns.create.assets_url_invalid;
      }
      final cpm = _parseMajorMoney(_cpmCtrl.text);
      if (cpm == null || cpm <= 0) {
        return t.advertiser_campaigns.create.validation_title;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final t = context.t;
    final err = _validate(t);
    if (err != null) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final budget = _parseMajorMoney(_budgetCtrl.text)!;
    final budgetCents = (budget * 100).round();

    final Map<String, dynamic> body;
    switch (_typeApi) {
      case 'VIDEO':
        final cpm = _parseMajorMoney(_cpmCtrl.text)!;
        body = AdvertiserCampaignCreatePayload.draft(
          title: _titleCtrl.text,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text,
          type: 'VIDEO',
          niche: _nicheApi,
          campaignObjective: _objectiveApi,
          assetsUrl: _assetsCtrl.text,
          totalBudgetCents: budgetCents,
          cpmCents: (cpm * 100).round(),
          videoMinDurationMinutes: _videoMinMinutes,
          videoRequirements: <String, dynamic>{
            'requiredPlatform': 'YOUTUBE',
            'allowMultiplePosts': false,
          },
        );
        break;
      case 'SHORTS':
        final cpm = _parseMajorMoney(_cpmCtrl.text)!;
        body = AdvertiserCampaignCreatePayload.draft(
          title: _titleCtrl.text,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text,
          type: 'SHORTS',
          niche: _nicheApi,
          campaignObjective: _objectiveApi,
          assetsUrl: _assetsCtrl.text,
          totalBudgetCents: budgetCents,
          cpmCents: (cpm * 100).round(),
          shortsPlatform: _shortsPlatformApi,
          shortsMaxDurationSeconds: _shortsMaxSeconds,
          shortsRequireVertical: false,
          shortsRequireLinkInBio: false,
        );
        break;
      default:
        final cpc = _parseMajorMoney(_cpcCtrl.text)!;
        body = AdvertiserCampaignCreatePayload.draft(
          title: _titleCtrl.text,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text,
          type: 'LINK',
          niche: _nicheApi,
          campaignObjective: _objectiveApi,
          landingUrl: _landingCtrl.text.trim(),
          totalBudgetCents: budgetCents,
          cpmCents: 0,
          cpcCents: (cpc * 100).round(),
        );
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(advertiserCampaignsRepositoryProvider);
      final id = await repo.createCampaignDraft(body);
      ref.invalidate(advertiserCampaignsPagedProvider);
      ref.invalidate(advertiserCampaignsCountsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.advertiser_campaigns.create.success)),
      );
      context.pushReplacement('/campaigns/$id');
    } catch (e) {
      if (!mounted) return;
      final msg = AdvertiserCampaignsRepository.mapError(e);
      final tip = msg is ServerException && msg.message.isNotEmpty
          ? msg.message
          : msg is NetworkException && msg.message.isNotEmpty
          ? msg.message
          : t.errors.server_generic;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tip)));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.advertiser_campaigns.create.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Text(
            t.advertiser_campaigns.create.section_basics,
            style: AppTextStyles.labelLarge(context).copyWith(
              color: AppColors.textMutedOf(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'LINK',
                label: Text(t.advertiser_campaigns.create.type_link),
              ),
              ButtonSegment(
                value: 'VIDEO',
                label: Text(t.advertiser_campaigns.create.type_video),
              ),
              ButtonSegment(
                value: 'SHORTS',
                label: Text(t.advertiser_campaigns.create.type_shorts),
              ),
            ],
            selected: {_typeApi},
            onSelectionChanged: (set) {
              final v = set.first;
              setState(() {
                _typeApi = v;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _objectiveApi,
            decoration: InputDecoration(
              labelText: t.advertiser_campaigns.create.field_objective,
            ),
            items: [
              DropdownMenuItem(
                value: 'AWARENESS',
                child: Text(t.advertiser_campaigns.detail.objective_awareness),
              ),
              DropdownMenuItem(
                value: 'TRAFFIC',
                child: Text(t.advertiser_campaigns.detail.objective_traffic),
              ),
              DropdownMenuItem(
                value: 'CONVERSION',
                child: Text(t.advertiser_campaigns.detail.objective_conversion),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _objectiveApi = v);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _nicheApi,
            decoration: InputDecoration(
              labelText: t.advertiser_campaigns.create.field_niche,
            ),
            items: [
              for (final n in kCampaignNicheApiValues)
                DropdownMenuItem(
                  value: n,
                  child: Text(
                    campaignNicheFallbackLabel(n),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _nicheApi = v ?? _nicheApi),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: t.advertiser_campaigns.create.field_title,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: t.advertiser_campaigns.create.field_description,
            ),
          ),
          const SizedBox(height: 18),
          if (_typeApi == 'LINK') ...[
            TextField(
              controller: _landingCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: t.advertiser_campaigns.create.field_landing,
                helperText: t.advertiser_campaigns.create.landing_help,
              ),
            ),
          ] else ...[
            TextField(
              controller: _assetsCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: t.advertiser_campaigns.create.field_assets,
                helperText: t.advertiser_campaigns.create.assets_help,
              ),
            ),
          ],
          if (_typeApi == 'VIDEO') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _videoMinMinutes,
              decoration: InputDecoration(
                labelText:
                    t.advertiser_campaigns.create.field_video_min_duration,
              ),
              items: [
                for (var m = 1; m <= 10; m++)
                  DropdownMenuItem(value: m, child: Text('$m min')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _videoMinMinutes = v);
                }
              },
            ),
          ],
          if (_typeApi == 'SHORTS') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _shortsPlatformApi,
              decoration: InputDecoration(
                labelText: t.advertiser_campaigns.detail.platform_label,
              ),
              items: [
                DropdownMenuItem(
                  value: 'YOUTUBE',
                  child: Text(t.advertiser_campaigns.platform.youtube),
                ),
                DropdownMenuItem(
                  value: 'TIKTOK',
                  child: Text(t.advertiser_campaigns.platform.tiktok),
                ),
                DropdownMenuItem(
                  value: 'INSTAGRAM',
                  child: Text(t.advertiser_campaigns.platform.instagram),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _shortsPlatformApi = v);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _shortsMaxSeconds,
              decoration: InputDecoration(
                labelText:
                    t.advertiser_campaigns.create.field_shorts_max_duration,
              ),
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 s')),
                DropdownMenuItem(value: 20, child: Text('20 s')),
                DropdownMenuItem(value: 30, child: Text('30 s')),
                DropdownMenuItem(value: 45, child: Text('45 s')),
                DropdownMenuItem(value: 60, child: Text('60 s')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _shortsMaxSeconds = v);
                }
              },
            ),
          ],
          const SizedBox(height: 24),
          Text(
            t.advertiser_campaigns.create.section_budget,
            style: AppTextStyles.labelLarge(context).copyWith(
              color: AppColors.textMutedOf(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: t.advertiser_campaigns.create.field_budget,
            ),
          ),
          const SizedBox(height: 12),
          if (_typeApi == 'LINK')
            TextField(
              controller: _cpcCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t.advertiser_campaigns.card.cpc,
                helperText: t.advertiser_campaigns.create.field_cpc_hint,
              ),
            )
          else
            TextField(
              controller: _cpmCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: t.advertiser_campaigns.detail.cpm_metric,
                helperText: t.advertiser_campaigns.create.field_cpm_hint,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _submitting ? null : () => _submit(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _submitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(t.advertiser_campaigns.create.submit_in_progress),
                    ],
                  )
                : Text(t.advertiser_campaigns.create.submit_draft),
          ),
        ),
      ),
    );
  }
}
