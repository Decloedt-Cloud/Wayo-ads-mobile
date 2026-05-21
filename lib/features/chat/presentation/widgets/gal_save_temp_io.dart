import 'dart:io';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Writes bytes to a temp image file (suffix e.g. `.jpg`) then [Gal.putImage].
/// Cleans up the file afterward. Not available on web.
Future<void> galPutImageViaTempFile(List<int> bytes, String fileSuffix) async {
  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}/wayo_${DateTime.now().microsecondsSinceEpoch}$fileSuffix';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  try {
    await Gal.putImage(file.path);
  } finally {
    try {
      await file.delete();
    } catch (_) {}
  }
}
