// Generates Play Console listing images from existing brand PNGs.
// Run from repo root: dart run tool/generate_play_store_listing_assets.dart
import 'dart:io';

import 'package:image/image.dart';

void main() {
  final root = Directory.current.path;
  final sourcePath = '$root/assets/android-chrome-192x192.png';
  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Missing source: $sourcePath');
    exit(1);
  }

  final src = decodeImage(sourceFile.readAsBytesSync());
  if (src == null) {
    stderr.writeln('Could not decode $sourcePath');
    exit(1);
  }

  final bg = ColorUint8.rgb(10, 10, 10);

  // Play Store listing icon: 512×512, PNG ≤ 1 MB (solid background, no transparency).
  final icon = Image(width: 512, height: 512, numChannels: 3);
  fill(icon, color: bg);
  final iconMark = copyResize(
    src,
    width: 384,
    height: 384,
    interpolation: Interpolation.cubic,
    backgroundColor: bg,
  );
  compositeImage(icon, iconMark, center: true);

  // Feature graphic: 1024×500, PNG ≤ 15 MB.
  final feature = Image(width: 1024, height: 500, numChannels: 3);
  fill(feature, color: bg);
  final featureMark = copyResize(
    src,
    width: 340,
    height: 340,
    interpolation: Interpolation.cubic,
    backgroundColor: bg,
  );
  compositeImage(feature, featureMark, center: true);

  final outDir = Directory('$root/assets/store_listing');
  outDir.createSync(recursive: true);

  final iconPath = '${outDir.path}/play_store_icon_512.png';
  final featurePath = '${outDir.path}/feature_graphic_1024x500.png';

  File(iconPath).writeAsBytesSync(encodePng(icon, level: 9));
  File(featurePath).writeAsBytesSync(encodePng(feature, level: 9));

  stdout.writeln('Wrote $iconPath (${File(iconPath).lengthSync()} bytes)');
  stdout.writeln('Wrote $featurePath (${File(featurePath).lengthSync()} bytes)');
}
