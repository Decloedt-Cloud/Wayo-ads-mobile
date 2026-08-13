import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect;

import 'package:image/image.dart' as img;

/// Client-side logo prep aligned with web `CampaignBannerCropDialog` (16:9)
/// and `POST /api/campaigns/upload-logo` / `crop-image.ts`.
abstract final class CampaignLogoPrep {
  static const maxBytes = 2 * 1024 * 1024;
  static const allowedMimes = {'image/png', 'image/jpeg', 'image/webp'};

  /// Web crop-image.ts max output.
  static const maxWidth = 1920;
  static const maxHeight = 1080;
  static const aspectW = 16;
  static const aspectH = 9;
  static const targetAspect = aspectW / aspectH;

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

  static img.Image? decode(Uint8List raw) {
    if (raw.isEmpty || raw.lengthInBytes > maxBytes) return null;
    final mime = detectMime(raw);
    if (mime == null || !allowedMimes.contains(mime)) return null;
    return img.decodeImage(raw);
  }

  /// Crop a pixel rectangle (web `getCroppedImageDataUrl`) then resize ≤1920×1080.
  static ({Uint8List bytes, String mime})? cropPixels(
    Uint8List raw, {
    required Rect pixelCrop,
  }) {
    final decoded = decode(raw);
    if (decoded == null) return null;

    final x = pixelCrop.left.round().clamp(0, decoded.width - 1);
    final y = pixelCrop.top.round().clamp(0, decoded.height - 1);
    final maxW = decoded.width - x;
    final maxH = decoded.height - y;
    final w = pixelCrop.width.round().clamp(1, maxW);
    final h = pixelCrop.height.round().clamp(1, maxH);

    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);

    var outImg = cropped;
    if (cropped.width > maxWidth || cropped.height > maxHeight) {
      final scale = math.min(
        maxWidth / cropped.width,
        maxHeight / cropped.height,
      );
      outImg = img.copyResize(
        cropped,
        width: math.max(1, (cropped.width * scale).round()),
        height: math.max(1, (cropped.height * scale).round()),
        interpolation: img.Interpolation.average,
      );
    }

    final mime = detectMime(raw) ?? 'image/jpeg';
    if (mime == 'image/png') {
      final out = Uint8List.fromList(img.encodePng(outImg));
      if (out.lengthInBytes > maxBytes) return null;
      return (bytes: out, mime: 'image/png');
    }

    final out = Uint8List.fromList(img.encodeJpg(outImg, quality: 90));
    if (out.lengthInBytes > maxBytes) return null;
    return (bytes: out, mime: 'image/jpeg');
  }

  /// Center 16:9 crop fallback.
  static ({Uint8List bytes, String mime})? prepareForUpload(
    Uint8List raw, {
    double focusX = 0.5,
    double focusY = 0.5,
    double zoom = 1.0,
  }) {
    final decoded = decode(raw);
    if (decoded == null) return null;
    final rect = cropRectForViewport(
      imageWidth: decoded.width,
      imageHeight: decoded.height,
      viewportWidth: 1600,
      viewportHeight: 900,
      zoom: zoom.clamp(1.0, 3.0),
      pan: Offset.zero,
    );
    // Nudge center toward focus for legacy callers.
    final cx = rect.center.dx + (focusX - 0.5) * decoded.width * 0.25;
    final cy = rect.center.dy + (focusY - 0.5) * decoded.height * 0.25;
    final shifted = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rect.width,
      height: rect.height,
    );
    return cropPixels(raw, pixelCrop: shifted);
  }

  /// Maps a 16:9 viewport + pan/zoom (cover fit) onto source image pixels.
  ///
  /// [pan] is in viewport pixels (positive = image moved right/down).
  /// [zoom] is 1..3 relative to the cover base scale (web slider).
  static Rect cropRectForViewport({
    required int imageWidth,
    required int imageHeight,
    required double viewportWidth,
    required double viewportHeight,
    required double zoom,
    required Offset pan,
  }) {
    final z = zoom.clamp(1.0, 3.0);
    final baseScale = math.max(
      viewportWidth / imageWidth,
      viewportHeight / imageHeight,
    );
    final scale = baseScale * z;
    final displayW = imageWidth * scale;
    final displayH = imageHeight * scale;

    final originX = (viewportWidth - displayW) / 2 + pan.dx;
    final originY = (viewportHeight - displayH) / 2 + pan.dy;

    var srcX = -originX / scale;
    var srcY = -originY / scale;
    var srcW = viewportWidth / scale;
    var srcH = viewportHeight / scale;

    if (srcW > imageWidth) {
      srcX = 0;
      srcW = imageWidth.toDouble();
    } else {
      srcX = srcX.clamp(0.0, imageWidth - srcW);
    }
    if (srcH > imageHeight) {
      srcY = 0;
      srcH = imageHeight.toDouble();
    } else {
      srcY = srcY.clamp(0.0, imageHeight - srcH);
    }

    return Rect.fromLTWH(srcX, srcY, srcW, srcH);
  }

  /// Max pan so the image still covers the viewport at [zoom].
  static Offset clampPan({
    required int imageWidth,
    required int imageHeight,
    required double viewportWidth,
    required double viewportHeight,
    required double zoom,
    required Offset pan,
  }) {
    final z = zoom.clamp(1.0, 3.0);
    final baseScale = math.max(
      viewportWidth / imageWidth,
      viewportHeight / imageHeight,
    );
    final scale = baseScale * z;
    final displayW = imageWidth * scale;
    final displayH = imageHeight * scale;
    final maxDx = math.max(0.0, (displayW - viewportWidth) / 2);
    final maxDy = math.max(0.0, (displayH - viewportHeight) / 2);
    return Offset(
      pan.dx.clamp(-maxDx, maxDx),
      pan.dy.clamp(-maxDy, maxDy),
    );
  }

  static String toDataUrl(Uint8List bytes, String mime) =>
      'data:$mime;base64,${base64Encode(bytes)}';
}
