import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:wayoadsgo/core/ui/wayo_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/auth_exceptions.dart';
import '../../../../core/network/wayo_ads_public_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/wayo_toast.dart';
import '../../../../i18n/strings.g.dart';
import '../../../dashboard/domain/entities/campaign_status.dart';
import '../../../dashboard/presentation/providers/dashboard_state_providers.dart';
import '../../../wallet/presentation/providers/advertiser_wallet_providers.dart';
import '../../data/advertiser_campaigns_repository.dart';
import '../../data/campaign_cost_remote.dart';
import '../../domain/campaign_cost_estimate.dart';
import '../../domain/campaign_editor_draft.dart';
import '../../domain/campaign_editor_validators.dart';
import '../../domain/campaign_logo_prep.dart';
import '../widgets/campaign_logo_crop_dialog.dart';
import '../../domain/campaign_mutation_result.dart';
import '../../domain/campaign_niche_catalog.dart';
import '../providers/advertiser_campaigns_providers.dart';
import '../widgets/campaign_editor_chrome.dart';

const _kLocalDraftKey = 'wayo_ads_campaign_editor_draft_v1';

/// Phase of the create/edit coordinator (UI state machine).
enum CampaignEditorPhase {
  initial,
  editing,
  validating,
  uploading,
  submitting,
  success,
  failure,
}

String _authErrorMessage(AuthException e) => switch (e) {
  InvalidCredentialsException(:final message) => message,
  NetworkException(:final message) => message,
  ServerException(:final message) => message,
  EmailNotRegisteredException(:final message) => message,
  CampaignInsufficientFundsException(:final message) => message,
  RateLimitedException(:final retryAfterSeconds) =>
    'Too many requests. Retry in ${retryAfterSeconds}s',
  SessionInvalidException() => 'Session expired',
};

String _newIdempotencyKey() {
  final r = Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Multi-step campaign create/edit wizard — 3 steps matching web.
class CampaignEditorScreen extends ConsumerStatefulWidget {
  const CampaignEditorScreen({super.key, this.campaignId});

  final String? campaignId;

  @override
  ConsumerState<CampaignEditorScreen> createState() =>
      _CampaignEditorScreenState();
}

class _CampaignEditorScreenState extends ConsumerState<CampaignEditorScreen>
    with WidgetsBindingObserver {
  static const _stepCount = 3;

  final _pageController = PageController();
  var _step = 0;
  var _phase = CampaignEditorPhase.initial;
  var _dirty = false;
  var _loading = false;
  var _navigatingAway = false;
  String? _error;
  String? _submitIdempotencyKey;
  int _submitGeneration = 0;
  Uint8List? _pendingLogoPreview;
  late CampaignEditorDraft _draft;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _landingCtrl = TextEditingController();
  final _assetsCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController(text: '10');
  final _cpmCtrl = TextEditingController(text: '1');
  final _cpcCtrl = TextEditingController(text: '0.10');
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController(text: '50');
  final _endDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _maxPayoutCtrl = TextEditingController();
  final _hashtagCtrl = TextEditingController();

  bool get _isEdit => widget.campaignId != null;
  bool get _busy =>
      _phase == CampaignEditorPhase.submitting ||
      _phase == CampaignEditorPhase.uploading;

  TranslationsAdvertiserCampaignsCreateEn get _c =>
      context.t.advertiser_campaigns.create;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _draft = CampaignEditorDraft(serverId: widget.campaignId);
    // Fresh create intention → new idempotency key; edit / resume keep until first submit.
    if (!_isEdit) {
      _submitIdempotencyKey = _newIdempotencyKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _dirty && !_isEdit) {
      _persistLocal();
    }
  }

  Future<void> _bootstrap() async {
    if (_isEdit) {
      setState(() => _loading = true);
      try {
        final json = await ref
            .read(advertiserCampaignsRepositoryProvider)
            .loadCampaignDetail(widget.campaignId!);
        if (!mounted) return;
        _draft = CampaignEditorDraft.fromServerJson(json);
        _syncControllersFromDraft();
        setState(() {
          _phase = CampaignEditorPhase.editing;
          _dirty = false;
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = _authErrorMessage(
              AdvertiserCampaignsRepository.mapError(e),
            );
            _phase = CampaignEditorPhase.failure;
          });
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLocalDraftKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _draft = CampaignEditorDraft.fromLocalJson(map);
        _syncControllersFromDraft();
        if (mounted) {
          setState(() {
            _phase = CampaignEditorPhase.editing;
            _dirty = true;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _phase = CampaignEditorPhase.editing);
      }
    } else if (mounted) {
      setState(() => _phase = CampaignEditorPhase.editing);
    }
  }

  void _syncControllersFromDraft() {
    _titleCtrl.text = _draft.title;
    _descCtrl.text = _draft.description ?? '';
    _landingCtrl.text = _draft.landingUrl ?? '';
    _assetsCtrl.text = (_draft.assetsUrl ?? '').replaceAll(',', '\n');
    _budgetCtrl.text = (_draft.totalBudgetCents / 100).toStringAsFixed(
      _draft.totalBudgetCents % 100 == 0 ? 0 : 2,
    );
    _cpmCtrl.text = (_draft.cpmCents / 100).toStringAsFixed(
      _draft.cpmCents % 100 == 0 ? 0 : 2,
    );
    final cpc = _draft.cpcCents ?? 0;
    _cpcCtrl.text = (cpc / 100).toStringAsFixed(cpc % 100 == 0 ? 0 : 2);
    _countryCtrl.text = _draft.targetCountryCode ?? '';
    _cityCtrl.text = _draft.targetCity ?? '';
    _radiusCtrl.text = '${_draft.targetRadiusKm ?? 50}';
    _endDateCtrl.text = _draft.campaignEndDate ?? '';
    _notesCtrl.text = _draft.notes ?? '';
    _hashtagCtrl.text = _draft.shortsRequireHashtag ?? '';
    if (_draft.maxPayoutCentsPerVideo != null) {
      final m = _draft.maxPayoutCentsPerVideo!;
      _maxPayoutCtrl.text = (m / 100).toStringAsFixed(m % 100 == 0 ? 0 : 2);
    } else {
      _maxPayoutCtrl.clear();
    }
  }

  void _pullControllersIntoDraft() {
    _draft.title = _titleCtrl.text;
    _draft.description = _descCtrl.text;
    var landing = _landingCtrl.text.trim();
    if (landing.isNotEmpty &&
        !landing.startsWith('http://') &&
        !landing.startsWith('https://')) {
      landing = 'https://$landing';
    }
    _draft.landingUrl = landing.isEmpty ? null : landing;
    final assetsRaw = _assetsCtrl.text
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(',');
    _draft.assetsUrl = assetsRaw.isEmpty ? null : assetsRaw;
    _draft.notes = _notesCtrl.text;
    _draft.targetCountryCode = _countryCtrl.text.toUpperCase().trim();
    _draft.targetCity = _cityCtrl.text.trim();
    _draft.campaignEndDate = _endDateCtrl.text.trim();
    _draft.shortsRequireHashtag = _hashtagCtrl.text.trim().isEmpty
        ? null
        : _hashtagCtrl.text.trim();
    final budget = double.tryParse(_budgetCtrl.text.replaceAll(',', '.'));
    if (budget != null) {
      _draft.totalBudgetCents = (budget * 100).round().clamp(
        CampaignEditorValidators.minBudgetCents,
        CampaignEditorValidators.maxBudgetCents,
      );
    }
    final cpm = double.tryParse(_cpmCtrl.text.replaceAll(',', '.'));
    if (cpm != null) {
      _draft.cpmCents = (cpm * 100).round().clamp(
        0,
        CampaignEditorValidators.maxCpmCents,
      );
    }
    final cpc = double.tryParse(_cpcCtrl.text.replaceAll(',', '.'));
    if (cpc != null) {
      _draft.cpcCents = (cpc * 100).round().clamp(
        0,
        CampaignEditorValidators.maxCpcCents,
      );
    }
    final radius = int.tryParse(_radiusCtrl.text);
    if (radius != null) {
      _draft.targetRadiusKm = radius.clamp(1, 1000);
    }
    final maxPayout = double.tryParse(_maxPayoutCtrl.text.replaceAll(',', '.'));
    _draft.maxPayoutCentsPerVideo = maxPayout == null
        ? null
        : (maxPayout * 100).round();
  }

  Future<void> _persistLocal() async {
    if (_isEdit) return;
    _pullControllersIntoDraft();
    _dirty = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalDraftKey, jsonEncode(_draft.toLocalJson()));
  }

  Future<void> _clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocalDraftKey);
    _dirty = false;
  }

  String _mapValidationCode(String? code) {
    final c = _c;
    return switch (code) {
      'title_required' => c.validation_title_required,
      'title_long' => c.validation_title_long,
      'title_html' => c.validation_title_html,
      'niche_required' => c.validation_niche,
      'landing_required' => c.validation_landing,
      'landing_invalid' => c.validation_landing_invalid,
      'assets_required' => c.validation_assets,
      'assets_invalid' => c.validation_assets_invalid,
      'budget_min' => c.validation_budget_min,
      'budget_max' => c.validation_budget_max,
      'cpc_required' || 'cpc_max' => c.validation_cpc,
      'cpm_required' || 'cpm_max' => c.validation_cpm,
      'end_date' => c.validation_end_date,
      'end_date_past' => c.validation_end_date_past,
      'geo_country' => c.validation_geo_country,
      'geo_radius' => c.validation_geo_radius,
      'video_duration' => c.validation_video_duration,
      'shorts_duration' => c.validation_shorts_duration,
      'max_payout' => c.validation_max_payout,
      _ => c.validation_title,
    };
  }

  String? _validateStep(int step) {
    _pullControllersIntoDraft();
    final code = switch (step) {
      0 => CampaignEditorValidators.validateIdentity(_draft),
      1 => CampaignEditorValidators.validateBudget(_draft),
      _ => null,
    };
    return code == null ? null : _mapValidationCode(code);
  }

  Future<void> _goNext() async {
    setState(() => _phase = CampaignEditorPhase.validating);
    final err = _validateStep(_step);
    if (err != null) {
      setState(() {
        _error = err;
        _phase = CampaignEditorPhase.editing;
      });
      if (mounted) {
        CampaignEditorChrome.shoutError(
          context,
          message: err,
          title: _c.validation_title,
        );
      }
      return;
    }
    setState(() => _error = null);
    await _persistLocal();
    if (_step >= _stepCount - 1) {
      setState(() => _phase = CampaignEditorPhase.editing);
      return;
    }
    setState(() {
      _step++;
      _phase = CampaignEditorPhase.editing;
    });
    await _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() async {
    if (_step == 0) {
      final leave = await _confirmLeave();
      if (leave && mounted) context.pop();
      return;
    }
    setState(() {
      _error = null;
      _step--;
    });
    await _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty || _isEdit) return true;
    final c = _c;
    final ok = await showWayoDialog<bool>(
      context: context,
      builder: (ctx) => WayoAlertDialog(
        title: Text(c.discard_title),
        content: Text(c.discard_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(c.discard_stay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(c.discard_confirm),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _pickLogo() async {
    final c = _c;
    if (_busy) return;
    HapticFeedback.selectionClick();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return;
      if (bytes.length > CampaignLogoPrep.maxBytes) {
        if (mounted) WayoToast.error(context, c.logo_too_large);
        return;
      }
      if (CampaignLogoPrep.detectMime(bytes) == null) {
        if (mounted) WayoToast.error(context, c.logo_pick_error);
        return;
      }
      if (!mounted) return;
      final cropped = await showCampaignLogoCropDialog(
        context: context,
        rawBytes: bytes,
      );
      if (cropped == null || !mounted) return;
      setState(() {
        _pendingLogoPreview = cropped.bytes;
        _phase = CampaignEditorPhase.uploading;
      });
      final dataUrl = CampaignLogoPrep.toDataUrl(cropped.bytes, cropped.mime);
      final url = await ref
          .read(advertiserCampaignsRepositoryProvider)
          .uploadCampaignLogoDataUrl(dataUrl);
      if (!mounted) return;
      setState(() {
        _draft.brandLogoUrl = url;
        _pendingLogoPreview = null;
        _phase = CampaignEditorPhase.editing;
        _dirty = true;
      });
      await _persistLocal();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = CampaignEditorPhase.editing;
        _pendingLogoPreview = null;
      });
      final mapped = e is AuthException
          ? e
          : AdvertiserCampaignsRepository.mapError(e);
      final code = mapped is ServerException ? mapped.statusCode : null;
      final msg = switch (code) {
        401 => 'Session expired',
        403 => 'Not allowed to upload logo',
        413 => c.logo_too_large,
        400 || 422 => mapped.toString().isEmpty
            ? c.logo_upload_error
            : mapped.toString(),
        _ => _authErrorMessage(mapped),
      };
      WayoToast.error(context, msg.isEmpty ? c.logo_pick_error : msg);
    }
  }

  Future<void> _publish() async {
    if (_busy || _navigatingAway) return;
    final c = _c;
    _pullControllersIntoDraft();
    final estimate = ref
        .read(campaignCostEstimateProvider(_draft.totalBudgetCents))
        .asData
        ?.value;
    final wallet = ref.read(advertiserWalletPageProvider).asData?.value;
    final availableCents = wallet == null
        ? null
        : (wallet.balance.available * 100).round();
    final total = estimate?.totalCents ?? _draft.totalBudgetCents;
    if (availableCents != null && availableCents < total) {
      setState(() => _error = c.wallet_insufficient);
      CampaignEditorChrome.shoutError(
        context,
        message: c.wallet_insufficient,
        title: c.validation_title,
      );
      return;
    }

    final confirm = await showWayoDialog<bool>(
      context: context,
      builder: (ctx) => WayoAlertDialog(
        title: Text(c.publish_confirm_title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.publish_confirm_body),
              if (estimate != null) ...[
                const SizedBox(height: 12),
                _costLines(c, estimate, availableCents),
              ],
              const SizedBox(height: 8),
              Text(
                c.cost_estimate_note,
                style: CampaignEditorChrome.hint(ctx),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(c.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: CampaignEditorChrome.amber,
              foregroundColor: Colors.black87,
            ),
            child: Text(c.publish),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _submit(publish: true);
  }

  Widget _costLines(
    TranslationsAdvertiserCampaignsCreateEn c,
    CampaignCostEstimate e,
    int? availableCents,
  ) {
    String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
    final remaining =
        availableCents == null ? null : availableCents - e.totalCents;
    final pctVal = e.platformFeeRate * 100;
    final pct = pctVal.toStringAsFixed(pctVal == pctVal.roundToDouble() ? 0 : 1);
    final taxLabel = (e.taxLabel != null && e.taxLabel!.isNotEmpty)
        ? c.cost_tax_named(label: e.taxLabel!)
        : c.cost_tax;
    TextStyle line() => GoogleFonts.dmSans(
          fontSize: 13.5,
          height: 1.45,
          color: AppColors.textPrimaryOf(context),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${c.cost_budget}: ${money(e.budgetCents)}', style: line()),
        Text(
          '${c.cost_platform_fee(pct: pct)}: ${money(e.platformFeeCents)}',
          style: line(),
        ),
        Text('$taxLabel: ${money(e.taxCents)}', style: line()),
        Text(
          '${c.cost_total}: ${money(e.totalCents)}',
          style: GoogleFonts.sora(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: CampaignEditorChrome.amber,
          ),
        ),
        if (availableCents != null)
          Text('${c.cost_available}: ${money(availableCents)}', style: line()),
        if (remaining != null)
          Text('${c.cost_remaining}: ${money(remaining)}', style: line()),
      ],
    );
  }

  Future<void> _submit({required bool publish}) async {
    if (_busy || _navigatingAway) return;
    for (var i = 0; i < _stepCount - 1; i++) {
      final err = _validateStep(i);
      if (err != null) {
        setState(() {
          _error = err;
          _step = i;
          _phase = CampaignEditorPhase.editing;
        });
        _pageController.jumpToPage(i);
        CampaignEditorChrome.shoutError(
          context,
          message: err,
          title: _c.validation_title,
        );
        return;
      }
    }

    _pullControllersIntoDraft();
    if (publish) {
      final estimate = ref
          .read(campaignCostEstimateProvider(_draft.totalBudgetCents))
          .asData
          ?.value;
      final wallet = ref.read(advertiserWalletPageProvider).asData?.value;
      if (wallet != null) {
        final availableCents = (wallet.balance.available * 100).round();
        final need = estimate?.totalCents ?? _draft.totalBudgetCents;
        if (availableCents < need) {
          setState(() => _error = _c.wallet_insufficient);
          CampaignEditorChrome.shoutError(
            context,
            message: _c.wallet_insufficient,
            title: _c.validation_title,
          );
          return;
        }
      }
    }

    final gen = ++_submitGeneration;
    setState(() {
      _phase = CampaignEditorPhase.submitting;
      _error = null;
    });
    _draft.status = publish ? CampaignStatus.active : CampaignStatus.draft;
    _submitIdempotencyKey ??= _newIdempotencyKey();

    try {
      final repo = ref.read(advertiserCampaignsRepositoryProvider);
      final body = _draft.toApiBody(includeStatus: true);
      final CampaignMutationResult result;
      if (_draft.serverId != null && _draft.serverId!.isNotEmpty) {
        result = await repo.updateCampaign(_draft.serverId!, body);
      } else {
        result = await repo.createCampaign(
          body,
          idempotencyKey: _submitIdempotencyKey,
        );
        _draft.serverId = result.id;
      }
      if (gen != _submitGeneration) return;
      _submitIdempotencyKey = null;
      await _clearLocal();
      _invalidateAfterMutation(result.id);
      if (!mounted) return;
      final successMsg = result.isActive ? _c.success_live : _c.success;
      final campaignId = result.id;
      setState(() {
        _phase = CampaignEditorPhase.success;
        _navigatingAway = true;
      });
      // Toast via root messenger before route change — avoids deactivated ancestor.
      WayoToast.success(context, successMsg);
      if (!mounted) return;
      context.go('/campaigns/$campaignId');
    } on CampaignInsufficientFundsException catch (e) {
      if (gen != _submitGeneration) return;
      if (!mounted) return;
      if (e.draftCampaignId != null && e.draftCampaignId!.isNotEmpty) {
        _draft.serverId = e.draftCampaignId;
        await _persistLocal();
      }
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _phase = CampaignEditorPhase.failure;
      });
      CampaignEditorChrome.shoutError(context, message: e.message);
    } catch (e) {
      if (gen != _submitGeneration) return;
      if (!mounted) return;
      final mapped = e is AuthException
          ? e
          : AdvertiserCampaignsRepository.mapError(e);
      if (mapped is SessionInvalidException) {
        setState(() {
          _error = _authErrorMessage(mapped);
          _phase = CampaignEditorPhase.failure;
        });
        return;
      }
      final keepKey = mapped is NetworkException ||
          (mapped is ServerException &&
              (mapped.statusCode == null || mapped.statusCode! >= 500)) ||
          mapped is CampaignInsufficientFundsException;
      if (!keepKey) {
        _submitIdempotencyKey = _newIdempotencyKey();
      }
      final msg = _authErrorMessage(mapped);
      setState(() {
        _error = msg.isEmpty ? 'Request failed' : msg;
        _phase = CampaignEditorPhase.failure;
      });
      CampaignEditorChrome.shoutError(
        context,
        message: msg.isEmpty ? 'Request failed' : msg,
      );
    } finally {
      if (mounted && gen == _submitGeneration && !_navigatingAway) {
        setState(() {
          if (_phase == CampaignEditorPhase.submitting ||
              _phase == CampaignEditorPhase.failure) {
            _phase = CampaignEditorPhase.editing;
          }
        });
      }
    }
  }

  void _invalidateAfterMutation(String id) {
    ref.invalidate(advertiserCampaignsPagedProvider);
    ref.invalidate(advertiserCampaignsCountsProvider);
    ref.invalidate(advertiserCampaignDetailProvider(id));
    ref.invalidate(advertiserWalletPageProvider);
    ref.invalidate(dashboardStreamProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _submitGeneration++;
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _landingCtrl.dispose();
    _assetsCtrl.dispose();
    _budgetCtrl.dispose();
    _cpmCtrl.dispose();
    _cpcCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _radiusCtrl.dispose();
    _endDateCtrl.dispose();
    _notesCtrl.dispose();
    _maxPayoutCtrl.dispose();
    _hashtagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final walletAsync = ref.watch(advertiserWalletPageProvider);
    final stepLabels = const ['Identity', 'Budget', 'Review'];

    return PopScope(
      canPop: !_dirty || _isEdit,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        final leave = await _confirmLeave();
        if (!mounted) return;
        if (leave) router.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _isEdit ? c.edit_title : c.title,
            style: CampaignEditorChrome.display(context),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevatedOf(context).withValues(alpha: 0.7),
              ),
              child: const Icon(Icons.close_rounded, size: 18),
            ),
            onPressed: _busy
                ? null
                : () async {
                    final router = GoRouter.of(context);
                    final leave = await _confirmLeave();
                    if (!mounted) return;
                    if (leave) router.pop();
                  },
          ),
        ),
        body: DecoratedBox(
          decoration: CampaignEditorChrome.pageBackground(context),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: CampaignEditorChrome.amber,
                  ),
                )
              : Column(
                  children: [
                    CampaignEditorStepRail(
                      step: _step,
                      total: _stepCount,
                      labels: stepLabels,
                      stepOfLabel: c.step_of(
                        current: _step + 1,
                        total: _stepCount,
                      ),
                    ),
                    walletAsync.when(
                      data: (w) => Align(
                        alignment: Alignment.centerLeft,
                        child: CampaignEditorWalletChip(
                          label: c.wallet_available(
                            amount:
                                '${w.balance.currency} ${w.balance.available.toStringAsFixed(2)}',
                          ),
                          low: w.balance.available <= 0,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    if (_error != null)
                      CampaignEditorErrorPanel(
                        message: _error!,
                        onDismiss: () => setState(() => _error = null),
                      ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _stepIdentity(c),
                          _stepBudget(c),
                          _stepReview(c),
                        ],
                      ),
                    ),
                    if (_step < _stepCount - 1)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Row(
                            children: [
                              TextButton(
                                onPressed: _busy ? null : _goBack,
                                child: Text(_step == 0 ? c.close : c.back),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: _busy ? null : _goNext,
                                style: FilledButton.styleFrom(
                                  backgroundColor: CampaignEditorChrome.amber,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      c.continue_btn,
                                      style: GoogleFonts.sora(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          child: Row(
                            children: [
                              TextButton(
                                onPressed: _busy ? null : _goBack,
                                child: Text(c.back),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _submit(publish: false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        CampaignEditorChrome.amber,
                                    side: const BorderSide(
                                      color: CampaignEditorChrome.amber,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    c.submit_draft,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.sora(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        floatingActionButton: _loading || _step != _stepCount - 1
            ? null
            : FloatingActionButton.extended(
                onPressed: _busy ? null : _publish,
                backgroundColor: CampaignEditorChrome.amber,
                foregroundColor: Colors.black87,
                elevation: 8,
                icon: _phase == CampaignEditorPhase.submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      )
                    : const Icon(Icons.rocket_launch_rounded),
                label: Text(
                  c.publish,
                  style: GoogleFonts.sora(fontWeight: FontWeight.w800),
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryOf(context),
        ),
        decoration: CampaignEditorChrome.fieldDecoration(
          context,
          label: label,
          prefixIcon: icon,
        ),
        onChanged: (_) => _persistLocal(),
      ),
    );
  }

  Widget _stepIdentity(TranslationsAdvertiserCampaignsCreateEn c) {
    final logoUrl = normalizeWayoAdsMediaUrl(_draft.brandLogoUrl);
    final preview = _pendingLogoPreview;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        CampaignEditorPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.field_type, style: CampaignEditorChrome.section(context)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CampaignTypeTile(
                    label: c.type_link,
                    subtitle: 'Traffic · CPC',
                    icon: Icons.link_rounded,
                    selected: _draft.type == CampaignTypeApi.link,
                    onTap: () {
                      setState(() => _draft.applyType(CampaignTypeApi.link));
                      _persistLocal();
                    },
                  ),
                  const SizedBox(width: 8),
                  CampaignTypeTile(
                    label: c.type_video,
                    subtitle: 'Views · CPM',
                    icon: Icons.play_circle_outline_rounded,
                    selected: _draft.type == CampaignTypeApi.video,
                    onTap: () {
                      setState(() => _draft.applyType(CampaignTypeApi.video));
                      _persistLocal();
                    },
                  ),
                  const SizedBox(width: 8),
                  CampaignTypeTile(
                    label: c.type_shorts,
                    subtitle: 'Shorts · CPM',
                    icon: Icons.smartphone_rounded,
                    selected: _draft.type == CampaignTypeApi.shorts,
                    onTap: () {
                      setState(() => _draft.applyType(CampaignTypeApi.shorts));
                      _persistLocal();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${c.field_objective}: ${_draft.effectiveObjective.apiValue}',
                style: CampaignEditorChrome.hint(context),
              ),
              Text(
                c.objective_forced_hint,
                style: CampaignEditorChrome.hint(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CampaignEditorPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Campaign story', style: CampaignEditorChrome.section(context)),
              const SizedBox(height: 14),
              _field(_titleCtrl, c.field_title, icon: Icons.title_rounded),
              _field(
                _descCtrl,
                c.field_description,
                maxLines: 4,
                icon: Icons.notes_rounded,
              ),
              _NichePicker(
                label: c.field_niche,
                value: _draft.niche != null &&
                        kCampaignNicheApiValues.contains(_draft.niche)
                    ? _draft.niche
                    : null,
                onChanged: (v) {
                  setState(() => _draft.niche = v);
                  _persistLocal();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CampaignEditorPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.logo_section, style: CampaignEditorChrome.section(context)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: CampaignEditorChrome.amber.withValues(alpha: 0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CampaignEditorChrome.amber.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: preview != null
                          ? Image.memory(preview, fit: BoxFit.cover)
                          : logoUrl == null
                              ? ColoredBox(
                                  color: AppColors.surfaceElevatedOf(context),
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: AppColors.textMutedOf(context),
                                  ),
                                )
                              : Image.network(logoUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilledButton(
                          onPressed: _busy ? null : _pickLogo,
                          style: FilledButton.styleFrom(
                            backgroundColor: CampaignEditorChrome.amber,
                            foregroundColor: CampaignEditorChrome.ink,
                            disabledBackgroundColor: CampaignEditorChrome.amber
                                .withValues(alpha: 0.4),
                            disabledForegroundColor: CampaignEditorChrome.ink
                                .withValues(alpha: 0.45),
                          ),
                          child: Text(
                            _phase == CampaignEditorPhase.uploading
                                ? c.logo_uploading
                                : (logoUrl == null
                                    ? c.logo_pick
                                    : c.logo_change),
                          ),
                        ),
                        if (logoUrl != null)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () {
                                    setState(() => _draft.brandLogoUrl = null);
                                    _persistLocal();
                                  },
                            child: Text(c.logo_remove),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(c.logo_help, style: CampaignEditorChrome.hint(context)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_draft.type == CampaignTypeApi.link)
          CampaignEditorPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                  _landingCtrl,
                  c.field_landing,
                  icon: Icons.language_rounded,
                ),
                Text(c.landing_help, style: CampaignEditorChrome.hint(context)),
              ],
            ),
          ),
        if (_draft.type != CampaignTypeApi.link)
          CampaignEditorPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                  _assetsCtrl,
                  c.field_assets,
                  maxLines: 3,
                  icon: Icons.video_library_outlined,
                ),
                Text(c.assets_help, style: CampaignEditorChrome.hint(context)),
                const SizedBox(height: 4),
                Text(
                  c.platform_youtube_only,
                  style: CampaignEditorChrome.hint(context),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stepBudget(TranslationsAdvertiserCampaignsCreateEn c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        CampaignEditorPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spend & timeline', style: CampaignEditorChrome.section(context)),
              const SizedBox(height: 14),
              _field(
                _budgetCtrl,
                c.field_budget,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.payments_outlined,
              ),
              if (_draft.type == CampaignTypeApi.link)
                _field(
                  _cpcCtrl,
                  c.field_cpc_hint,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.touch_app_outlined,
                )
              else
                _field(
                  _cpmCtrl,
                  c.field_cpm_hint,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.visibility_outlined,
                ),
              _EndDatePickerField(
                controller: _endDateCtrl,
                label: c.end_date,
                onChanged: () => _persistLocal(),
              ),
            ],
          ),
        ),
        if (_draft.type == CampaignTypeApi.video) ...[
          const SizedBox(height: 14),
          CampaignEditorPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.field_video_min_duration,
                  style: CampaignEditorChrome.section(context),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var m = 1; m <= 10; m++)
                      _DurationChip(
                        label: '$m min',
                        selected: (_draft.videoMinDurationMinutes ?? 1) == m,
                        onTap: () {
                          setState(() => _draft.videoMinDurationMinutes = m);
                          _persistLocal();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (_draft.type == CampaignTypeApi.shorts) ...[
          const SizedBox(height: 14),
          CampaignEditorPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.field_shorts_max_duration,
                  style: CampaignEditorChrome.section(context),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in const [15, 20, 30, 45, 60])
                      _DurationChip(
                        label: '${s}s',
                        selected: (_draft.shortsMaxDurationSeconds ?? 60) == s,
                        onTap: () {
                          setState(() => _draft.shortsMaxDurationSeconds = s);
                          _persistLocal();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    c.shorts_vertical,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                  activeThumbColor: Colors.white,
                  activeTrackColor: CampaignEditorChrome.amber,
                  value: _draft.shortsRequireVertical ?? true,
                  onChanged: (v) {
                    setState(() => _draft.shortsRequireVertical = v);
                    _persistLocal();
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    c.shorts_link_in_bio,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                  activeThumbColor: Colors.white,
                  activeTrackColor: CampaignEditorChrome.amber,
                  value: _draft.shortsRequireLinkInBio ?? false,
                  onChanged: (v) {
                    setState(() => _draft.shortsRequireLinkInBio = v);
                    _persistLocal();
                  },
                ),
                _field(
                  _hashtagCtrl,
                  c.field_hashtag,
                  icon: Icons.tag_rounded,
                ),
              ],
            ),
          ),
        ],
        if (_draft.type != CampaignTypeApi.link) ...[
          const SizedBox(height: 14),
          CampaignEditorPanel(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    c.allow_multiple_posts,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                  activeThumbColor: Colors.white,
                  activeTrackColor: CampaignEditorChrome.amber,
                  value: _draft.allowMultiplePosts,
                  onChanged: (v) {
                    setState(() => _draft.allowMultiplePosts = v);
                    _persistLocal();
                  },
                ),
                _field(
                  _maxPayoutCtrl,
                  c.field_max_payout,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.savings_outlined,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        CampaignEditorPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  c.geo_enable,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
                activeThumbColor: Colors.white,
                activeTrackColor: CampaignEditorChrome.amber,
                value: _draft.isGeoTargeted,
                onChanged: (v) {
                  setState(() => _draft.isGeoTargeted = v);
                  _persistLocal();
                },
              ),
              if (_draft.isGeoTargeted) ...[
                _field(
                  _countryCtrl,
                  c.geo_country,
                  icon: Icons.public_rounded,
                ),
                _field(
                  _cityCtrl,
                  c.geo_city,
                  icon: Icons.location_city_rounded,
                ),
                _field(
                  _radiusCtrl,
                  c.geo_radius,
                  keyboardType: TextInputType.number,
                  icon: Icons.radar_rounded,
                ),
                Text(c.geo_privacy, style: CampaignEditorChrome.hint(context)),
              ],
              const SizedBox(height: 8),
              _field(
                _notesCtrl,
                c.notes_label,
                maxLines: 5,
                icon: Icons.sticky_note_2_outlined,
              ),
              Text(
                c.budget_authority_note,
                style: CampaignEditorChrome.hint(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepReview(TranslationsAdvertiserCampaignsCreateEn c) {
    final est = _draft.type == CampaignTypeApi.link
        ? (_draft.cpcCents != null && _draft.cpcCents! > 0
              ? (_draft.totalBudgetCents / _draft.cpcCents!).floor()
              : 0)
        : (_draft.cpmCents > 0
              ? ((_draft.totalBudgetCents / _draft.cpmCents) * 1000).floor()
              : 0);
    final costAsync = ref.watch(
      campaignCostEstimateProvider(_draft.totalBudgetCents),
    );
    final wallet = ref.watch(advertiserWalletPageProvider).asData?.value;
    final availableCents = wallet == null
        ? null
        : (wallet.balance.available * 100).round();
    final nicheLabel = _draft.niche == null
        ? '—'
        : campaignNicheDisplayLabel(_draft.niche!);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Text(c.review, style: CampaignEditorChrome.display(context)),
        const SizedBox(height: 6),
        Text(
          'Double-check before you go live.',
          style: CampaignEditorChrome.hint(context),
        ),
        const SizedBox(height: 16),
        CampaignEditorPanel(
          child: Column(
            children: [
              CampaignReviewRow(label: c.field_title, value: _draft.title),
              CampaignReviewRow(
                label: c.field_type,
                value: _draft.type.apiValue,
              ),
              CampaignReviewRow(
                label: c.field_objective,
                value: _draft.effectiveObjective.apiValue,
              ),
              CampaignReviewRow(label: c.field_niche, value: nicheLabel),
              CampaignReviewRow(
                label: c.field_budget,
                value: '\$${(_draft.totalBudgetCents / 100).toStringAsFixed(2)}',
              ),
              if (_draft.type == CampaignTypeApi.link)
                CampaignReviewRow(
                  label: c.field_cpc_hint,
                  value:
                      '\$${((_draft.cpcCents ?? 0) / 100).toStringAsFixed(2)}',
                )
              else
                CampaignReviewRow(
                  label: c.field_cpm_hint,
                  value: '\$${(_draft.cpmCents / 100).toStringAsFixed(2)}',
                ),
              CampaignReviewRow(
                label: c.end_date,
                value: _draft.campaignEndDate ?? '—',
              ),
              CampaignReviewRow(
                label: c.geo_enable,
                value: _draft.isGeoTargeted
                    ? '${_draft.targetCountryCode ?? '?'} / ${_draft.targetCity ?? '—'}'
                    : c.worldwide,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CampaignEditorPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _draft.type == CampaignTypeApi.link
                    ? c.estimate_clicks(count: est)
                    : c.estimate_impressions(count: est),
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 14),
              Text(c.cost_total, style: CampaignEditorChrome.section(context)),
              const SizedBox(height: 10),
              costAsync.when(
                loading: () => Text(
                  c.cost_loading,
                  style: CampaignEditorChrome.hint(context),
                ),
                error: (_, _) => Text(
                  c.cost_estimate_note,
                  style: CampaignEditorChrome.hint(context),
                ),
                data: (estimate) {
                  if (estimate == null) {
                    return Text(
                      c.cost_estimate_note,
                      style: CampaignEditorChrome.hint(context),
                    );
                  }
                  return _costLines(c, estimate, availableCents);
                },
              ),
              const SizedBox(height: 10),
              Text(
                c.cost_estimate_note,
                style: CampaignEditorChrome.hint(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? CampaignEditorChrome.amber.withValues(alpha: 0.2)
                : AppColors.surfaceElevatedOf(context).withValues(alpha: 0.55),
            border: Border.all(
              color: selected
                  ? CampaignEditorChrome.amber
                  : AppColors.borderOf(context).withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected
                  ? CampaignEditorChrome.amberDeep
                  : AppColors.textPrimaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// Searchable niche bottom-sheet picker (web-parity dropdown UX).
class _NichePicker extends StatelessWidget {
  const _NichePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _NichePickerSheet(initial: value),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final display = value == null ? null : campaignNicheDisplayLabel(value!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: CampaignEditorChrome.fieldDecoration(
            context,
            label: label,
            prefixIcon: Icons.category_outlined,
            suffix: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: CampaignEditorChrome.amber,
            ),
          ),
          child: Text(
            display ?? 'Select niche…',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: display == null
                  ? AppColors.textMutedOf(context)
                  : AppColors.textPrimaryOf(context),
              fontWeight: display == null ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _NichePickerSheet extends StatefulWidget {
  const _NichePickerSheet({this.initial});
  final String? initial;

  @override
  State<_NichePickerSheet> createState() => _NichePickerSheetState();
}

class _NichePickerSheetState extends State<_NichePickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final items = kCampaignNicheApiValues.where((n) {
      if (q.isEmpty) return true;
      return n.toLowerCase().contains(q) ||
          campaignNicheDisplayLabel(n).toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderOf(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose a niche',
                  style: CampaignEditorChrome.section(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: CampaignEditorChrome.fieldDecoration(
                  context,
                  label: 'Search',
                  hint: 'Search niches…',
                  prefixIcon: Icons.search_rounded,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final n = items[i];
                  final selected = n == widget.initial;
                  return ListTile(
                    title: Text(
                      campaignNicheDisplayLabel(n),
                      style: GoogleFonts.dmSans(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: CampaignEditorChrome.amber,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, n),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendar date picker writing `YYYY-MM-DD` into [controller].
class _EndDatePickerField extends StatelessWidget {
  const _EndDatePickerField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    DateTime initial = now;
    final existing = controller.text.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(existing)) {
      initial = DateTime.tryParse(existing) ?? now;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: CampaignEditorChrome.amber,
            onPrimary: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final y = picked.year.toString().padLeft(4, '0');
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    controller.text = '$y-$m-$d';
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () => _pick(context),
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryOf(context),
        ),
        decoration: CampaignEditorChrome.fieldDecoration(
          context,
          label: label,
          prefixIcon: Icons.event_rounded,
          suffix: IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: CampaignEditorChrome.amber,
            ),
            onPressed: () => _pick(context),
          ),
        ),
      ),
    );
  }
}
