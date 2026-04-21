import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// TLS public-key pinning for release builds (SHA-256 of DER cert, Base64).
///
/// // NOTE: Pins must match `sha256(der).bytes` encoded as Base64 (see SECURITY.md).
abstract final class CertificatePinning {
  static void attach(Dio dio, {required List<String> pinnedSha256Base64}) {
    if (!kReleaseMode) {
      return;
    }
    if (pinnedSha256Base64.isEmpty) {
      debugPrint(
        '[WARN][CertificatePinning] release build: empty CERT_PIN_* — pinning disabled',
      );
      return;
    }
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          final sha = base64.encode(sha256.convert(cert.der).bytes);
          return pinnedSha256Base64.contains(sha);
        };
        return client;
      },
    );
  }
}
