import 'dart:io';

import 'package:image/image.dart' as img;

/// Writes a 1152×1152 black PNG for `flutter_native_splash` Android 12.
/// Tiny images can make the OS fall back to the launcher adaptive icon.
void main() {
  const size = 1152;
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(0, 0, 0));

  const path = 'assets/splash/android12_splash_solid.png';
  File(path).writeAsBytesSync(img.encodePng(image));
  // ignore: avoid_print
  print('Wrote $path');
}
