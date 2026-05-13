import 'dart:io';

import 'package:image/image.dart' as img;

/// Builds a square PNG for [flutter_native_splash]: centered
/// [`assets/wayo ads mobile new.png`] scaled to ~¼ of canvas so the OS splash
/// shows a **small** mark on black (#000000 via yaml `color`).
///
/// Run from repo root: `dart run tool/gen_native_splash_small_logo.dart`
/// Then: `dart run flutter_native_splash:create`
void main() {
  const sourcePath = 'assets/wayo ads mobile new.png';
  const outPath = 'assets/branding/wayo_native_splash_logo.png';

  final srcBytes = File(sourcePath).readAsBytesSync();
  final src = img.decodePng(srcBytes);
  if (src == null) {
    stderr.writeln('Failed to decode $sourcePath');
    exit(1);
  }

  const canvasSide = 1152;
  const widthFraction =
      0.26; // smaller mark on screen (more padding vs full-bleed source)
  final targetW = (canvasSide * widthFraction).round();
  final ratio = targetW / src.width;
  final targetH = (src.height * ratio).round();
  final resized = img.copyResize(src, width: targetW, height: targetH);

  final canvas = img.Image(width: canvasSide, height: canvasSide, numChannels: 4)
    ..clear(img.ColorRgba8(0, 0, 0, 0));

  img.compositeImage(
    canvas,
    resized,
    dstX: (canvasSide - resized.width) ~/ 2,
    dstY: (canvasSide - resized.height) ~/ 2,
  );

  File(outPath).writeAsBytesSync(img.encodePng(canvas));
  // ignore: avoid_print
  print('Wrote $outPath (${canvasSide}px, logo ~${(widthFraction * 100).toStringAsFixed(0)}% width)');
}
