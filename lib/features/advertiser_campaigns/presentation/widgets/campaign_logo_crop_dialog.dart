import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/campaign_logo_prep.dart';
import 'campaign_editor_chrome.dart';

/// Interactive 16:9 crop — mirrors web `CampaignBannerCropDialog`
/// (pan + zoom 1×–3× + grid + apply).
Future<({Uint8List bytes, String mime})?> showCampaignLogoCropDialog({
  required BuildContext context,
  required Uint8List rawBytes,
}) {
  return showDialog<({Uint8List bytes, String mime})>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CampaignLogoCropDialog(rawBytes: rawBytes),
  );
}

class _CampaignLogoCropDialog extends StatefulWidget {
  const _CampaignLogoCropDialog({required this.rawBytes});
  final Uint8List rawBytes;

  @override
  State<_CampaignLogoCropDialog> createState() =>
      _CampaignLogoCropDialogState();
}

class _CampaignLogoCropDialogState extends State<_CampaignLogoCropDialog> {
  ui.Image? _image;
  String? _loadError;
  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  var _applying = false;
  String? _applyError;

  static const _minZoom = 1.0;
  static const _maxZoom = 3.0;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.rawBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _image = frame.image;
        _loadError = null;
        _zoom = 1.0;
        _pan = Offset.zero;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = context.t.advertiser_campaigns.create.logo_crop_failed);
    }
  }

  void _setZoom(double z) {
    final next = z.clamp(_minZoom, _maxZoom);
    final image = _image;
    final vp = _viewportSize;
    setState(() {
      _zoom = next;
      if (image != null && vp != null) {
        _pan = CampaignLogoPrep.clampPan(
          imageWidth: image.width,
          imageHeight: image.height,
          viewportWidth: vp.width,
          viewportHeight: vp.height,
          zoom: next,
          pan: _pan,
        );
      }
    });
  }

  Future<void> _apply(Size viewport) async {
    final image = _image;
    if (image == null || _applying) return;
    setState(() {
      _applying = true;
      _applyError = null;
    });
    HapticFeedback.lightImpact();
    try {
      final pan = CampaignLogoPrep.clampPan(
        imageWidth: image.width,
        imageHeight: image.height,
        viewportWidth: viewport.width,
        viewportHeight: viewport.height,
        zoom: _zoom,
        pan: _pan,
      );
      final rect = CampaignLogoPrep.cropRectForViewport(
        imageWidth: image.width,
        imageHeight: image.height,
        viewportWidth: viewport.width,
        viewportHeight: viewport.height,
        zoom: _zoom,
        pan: pan,
      );
      final prepared = CampaignLogoPrep.cropPixels(
        widget.rawBytes,
        pixelCrop: rect,
      );
      if (!mounted) return;
      if (prepared == null) {
        setState(() {
          _applying = false;
          _applyError =
              context.t.advertiser_campaigns.create.logo_crop_failed;
        });
        return;
      }
      Navigator.pop(context, prepared);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _applyError = context.t.advertiser_campaigns.create.logo_crop_failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.advertiser_campaigns.create;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF14121A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxH),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                t.logo_crop_title,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.logo_crop_desc,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 14),
              if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _loadError!,
                    style: TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (_image == null)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SizedBox(
                  height: math.min(
                    280,
                    MediaQuery.sizeOf(context).height * 0.38,
                  ),
                  child: _CropViewport(
                    image: _image!,
                    zoom: _zoom,
                    pan: _pan,
                    onPanZoom: (pan, zoom) {
                      setState(() {
                        _zoom = zoom;
                        _pan = pan;
                      });
                    },
                    onApplyReady: (viewport) => _viewportSize = viewport,
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    t.logo_crop_zoom,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_zoom.toStringAsFixed(1)}×',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: CampaignEditorChrome.amber,
                  inactiveTrackColor:
                      CampaignEditorChrome.amber.withValues(alpha: 0.2),
                  thumbColor: CampaignEditorChrome.amber,
                  overlayColor:
                      CampaignEditorChrome.amber.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: _zoom,
                  min: _minZoom,
                  max: _maxZoom,
                  divisions: 40,
                  onChanged: _image == null || _applying
                      ? null
                      : _setZoom,
                ),
              ),
              Text(
                t.logo_crop_hint,
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  height: 1.35,
                  color: AppColors.textMutedOf(context),
                ),
              ),
              if (_applyError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _applyError!,
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _applying
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondaryOf(context),
                        side: BorderSide(color: AppColors.borderOf(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(t.logo_crop_cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _image == null || _applying
                          ? null
                          : () {
                              final vp = _viewportSize;
                              if (vp == null || vp.width <= 0) return;
                              _apply(vp);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: CampaignEditorChrome.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _applying
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(t.logo_crop_applying),
                              ],
                            )
                          : Text(t.logo_crop_apply),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Size? _viewportSize;
}

class _CropViewport extends StatefulWidget {
  const _CropViewport({
    required this.image,
    required this.zoom,
    required this.pan,
    required this.onPanZoom,
    required this.onApplyReady,
  });

  final ui.Image image;
  final double zoom;
  final Offset pan;
  final void Function(Offset pan, double zoom) onPanZoom;
  final ValueChanged<Size> onApplyReady;

  @override
  State<_CropViewport> createState() => _CropViewportState();
}

class _CropViewportState extends State<_CropViewport> {
  double _gestureStartZoom = 1.0;
  Offset _gestureStartPan = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewW = constraints.maxWidth;
        final viewH = math.min(viewW * 9 / 16, constraints.maxHeight);
        final size = Size(viewW, viewH);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onApplyReady(size);
        });

        final clamped = CampaignLogoPrep.clampPan(
          imageWidth: widget.image.width,
          imageHeight: widget.image.height,
          viewportWidth: viewW,
          viewportHeight: viewH,
          zoom: widget.zoom,
          pan: widget.pan,
        );

        return Center(
          child: SizedBox(
            width: viewW,
            height: viewH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                onScaleStart: (d) {
                  _gestureStartZoom = widget.zoom;
                  _gestureStartPan = clamped;
                  _gestureStartFocal = d.focalPoint;
                },
                onScaleUpdate: (d) {
                  final nextZoom =
                      (_gestureStartZoom * d.scale).clamp(1.0, 3.0);
                  final drag = d.focalPoint - _gestureStartFocal;
                  final nextPan = CampaignLogoPrep.clampPan(
                    imageWidth: widget.image.width,
                    imageHeight: widget.image.height,
                    viewportWidth: viewW,
                    viewportHeight: viewH,
                    zoom: nextZoom,
                    pan: _gestureStartPan + drag,
                  );
                  widget.onPanZoom(nextPan, nextZoom);
                },
                child: CustomPaint(
                  size: size,
                  painter: _CropPainter(
                    image: widget.image,
                    zoom: widget.zoom,
                    pan: clamped,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter({
    required this.image,
    required this.zoom,
    required this.pan,
  });

  final ui.Image image;
  final double zoom;
  final Offset pan;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xE6000000),
    );

    final z = zoom.clamp(1.0, 3.0);
    final baseScale = math.max(
      size.width / image.width,
      size.height / image.height,
    );
    final scale = baseScale * z;
    final displayW = image.width * scale;
    final displayH = image.height * scale;
    final originX = (size.width - displayW) / 2 + pan.dx;
    final originY = (size.height - displayH) / 2 + pan.dy;

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(originX, originY, displayW, displayH);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.high);

    // Grid (rule of thirds) like web showGrid.
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Frame border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(0)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = CampaignEditorChrome.amber.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _CropPainter old) =>
      old.image != image || old.zoom != zoom || old.pan != pan;
}
