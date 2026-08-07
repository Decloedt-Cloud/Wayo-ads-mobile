import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/campaign_logo_prep.dart';

/// Interactive 16:9 framing dialog — mirrors web `CampaignBannerCropDialog`
/// (pan focus; center crop applied via [CampaignLogoPrep]).
Future<({Uint8List bytes, String mime})?> showCampaignLogoCropDialog({
  required BuildContext context,
  required Uint8List rawBytes,
}) {
  return showModalBottomSheet<({Uint8List bytes, String mime})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CampaignLogoCropSheet(rawBytes: rawBytes),
  );
}

class _CampaignLogoCropSheet extends StatefulWidget {
  const _CampaignLogoCropSheet({required this.rawBytes});
  final Uint8List rawBytes;

  @override
  State<_CampaignLogoCropSheet> createState() => _CampaignLogoCropSheetState();
}

class _CampaignLogoCropSheetState extends State<_CampaignLogoCropSheet> {
  double _focusX = 0.5;
  double _focusY = 0.5;
  Uint8List? _preview;
  String? _previewMime;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _recomputePreview();
  }

  void _recomputePreview() {
    final prepared = CampaignLogoPrep.prepareForUpload(
      widget.rawBytes,
      focusX: _focusX,
      focusY: _focusY,
    );
    setState(() {
      _preview = prepared?.bytes;
      _previewMime = prepared?.mime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      margin: const EdgeInsets.only(top: 48),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Crop banner (16:9)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Drag to frame the area creators will see on campaign cards.',
                style: TextStyle(color: AppColors.textMutedOf(context)),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onPanUpdate: (d) {
                      final box = context.findRenderObject() as RenderBox?;
                      // Approximate pan sensitivity against sheet width.
                      final w = box?.size.width ?? 360;
                      setState(() {
                        _focusX = (_focusX - d.delta.dx / w).clamp(0.0, 1.0);
                        _focusY = (_focusY - d.delta.dy / (w * 9 / 16))
                            .clamp(0.0, 1.0);
                      });
                      _recomputePreview();
                    },
                    child: ColoredBox(
                      color: Colors.black,
                      child: _preview == null
                          ? const Center(child: CircularProgressIndicator())
                          : Image.memory(_preview!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || _preview == null || _previewMime == null
                    ? null
                    : () {
                        setState(() => _busy = true);
                        Navigator.pop(context, (
                          bytes: _preview!,
                          mime: _previewMime!,
                        ));
                      },
                child: const Text('Use this crop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
