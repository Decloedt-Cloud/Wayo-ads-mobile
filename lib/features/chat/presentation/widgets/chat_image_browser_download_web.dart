// Web-only helpers; dart:html is correct for WASM and legacy web compilations here.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

/// Triggers a real browser download for [bytes] (not the system share sheet).
void triggerBrowserImageDownload(List<int> bytes, String mime, String filename) {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  unawaited(
    Future<void>.delayed(const Duration(seconds: 1), () {
      html.Url.revokeObjectUrl(url);
    }),
  );
}
