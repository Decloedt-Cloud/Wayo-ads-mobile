import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Client-side logo prep aligned with web `CampaignBannerCropDialog` (16:9)
/// and `POST /api/campaigns/upload-logo`.
abstract final class CampaignLogoPrep {
  static const maxBytes = 2 * 1024 * 1024;
  static const allowedMimes = {'image/png', 'image/jpeg', 'image/webp'};

  /// Web crop-image.ts max output.
  static const maxWidth = 1920;
  static const maxHeight = 1080;
  static const aspectW = 16;
  static const aspectH = 9;

  /// Detect mime from magic bytes (do not trust file extension alone).
  static String? detectMime(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  /// Center 16:9 crop + resize (≤1920×1080) + re-encode.
  ///
  /// For interactive framing, pass [focusX]/[focusY] in 0..1 (crop center
  /// relative to the source image). Defaults to image center.
  static ({Uint8List bytes, String mime})? prepareForUpload(
    Uint8List raw, {
    double focusX = 0.5,
    double focusY = 0.5,
  }) {
    if (raw.isEmpty || raw.lengthInBytes > maxBytes) return null;
    final mime = detectMime(raw);
    if (mime == null || !allowedMimes.contains(mime)) return null;

    final decoded = img.decodeImage(raw);
    if (decoded == null) return null;

    final crop = _cropRect16x9(
      decoded.width,
      decoded.height,
      focusX: focusX.clamp(0.0, 1.0),
      focusY: focusY.clamp(0.0, 1.0),
    );
    final cropped = img.copyCrop(
      decoded,
      x: crop.$1,
      y: crop.$2,
      width: crop.$3,
      height: crop.$4,
    );

    var outImg = cropped;
    if (cropped.width > maxWidth || cropped.height > maxHeight) {
      outImg = img.copyResize(
        cropped,
        width: maxWidth,
        height: maxHeight,
        interpolation: img.Interpolation.average,
      );
    }

    if (mime == 'image/png') {
      final out = Uint8List.fromList(img.encodePng(outImg));
      if (out.lengthInBytes > maxBytes) return null;
      return (bytes: out, mime: 'image/png');
    }

    final out = Uint8List.fromList(img.encodeJpg(outImg, quality: 88));
    if (out.lengthInBytes > maxBytes) return null;
    return (bytes: out, mime: 'image/jpeg');
  }

  /// Returns `(x, y, width, height)` for a 16:9 window inside [srcW]×[srcH].
  static (int, int, int, int) _cropRect16x9(
    int srcW,
    int srcH, {
    required double focusX,
    required double focusY,
  }) {
    final targetAspect = aspectW / aspectH;
    final srcAspect = srcW / srcH;
    late int cropW;
    late int cropH;
    if (srcAspect > targetAspect) {
      cropH = srcH;
      cropW = (srcH * targetAspect).round().clamp(1, srcW);
    } else {
      cropW = srcW;
      cropH = (srcW / targetAspect).round().clamp(1, srcH);
    }
    final maxX = srcW - cropW;
    final maxY = srcH - cropH;
    final cx = (focusX * srcW).round();
    final cy = (focusY * srcH).round();
    final x = (cx - cropW ~/ 2).clamp(0, maxX);
    final y = (cy - cropH ~/ 2).clamp(0, maxY);
    return (x, y, cropW, cropH);
  }

  static String toDataUrl(Uint8List bytes, String mime) =>
      'data:$mime;base64,${base64Encode(bytes)}';
}
