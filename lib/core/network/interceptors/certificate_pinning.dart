import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';
import '../../observability/app_log.dart';

/// TLS public-key pinning for release builds (SHA-256 of DER cert, Base64).
///
/// Pins must match `sha256(cert.der).bytes` encoded as Base64 (see SECURITY.md).
///
/// **Implementation note:** Dart's `badCertificateCallback` is only invoked when
/// the *default* TLS validation fails. To enforce pinning on *every* handshake,
/// we create an [HttpClient] with an *empty* [SecurityContext] (no trusted CAs),
/// so all server certificates fail default validation and trigger the callback
/// where we verify against our pins.
abstract final class CertificatePinning {
  /// Attaches certificate pinning to [dio].
  ///
  /// In **release** builds:
  /// - Throws [StateError] if [pinnedSha256Base64] is empty (fail-fast), unless
  ///   [AppConfig.disableCertPinning] is `true`.
  /// - Configures [HttpClient] to reject any cert not matching a pin.
  ///
  /// In **debug/profile** builds: no-op (allows dev servers without valid certs).
  static void attach(Dio dio, {required List<String> pinnedSha256Base64}) {
    if (!kReleaseMode) {
      return;
    }

    if (AppConfig.disableCertPinning) {
      wayoConfigDiagPrint(
        '[CertificatePinning] disabled (DISABLE_CERT_PINNING=true)',
        name: 'wayo.tls',
      );
      return;
    }

    // SECURITY: Empty pins in release is a configuration error — fail loudly.
    if (pinnedSha256Base64.isEmpty) {
      throw StateError(
        'Certificate pinning requires at least one pin in release builds. '
        'Set CERT_PIN_PRIMARY / CERT_PIN_BACKUP / CERT_PIN_EXTRA / CERT_PIN_ALT via --dart-define, '
        'or pass --dart-define=DISABLE_CERT_PINNING=true temporarily.',
      );
    }

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        // Use an empty SecurityContext so *all* certs fail default validation,
        // forcing badCertificateCallback to be invoked on every TLS handshake.
        final context = SecurityContext(withTrustedRoots: false);
        final client = HttpClient(context: context);

        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          final sha = base64.encode(sha256.convert(cert.der).bytes);
          final pinned = pinnedSha256Base64.contains(sha);
          if (!pinned) {
            if (kDebugMode) {
              debugPrint(
                '[CertificatePinning] REJECTED $host:$port — SHA256: $sha',
              );
            }
            wayoTlsDiagPrint(
              '[CertificatePinning] REJECTED $host:$port peerSha256=$sha '
              '(update CERT_PIN_* or compare with openssl output; '
              'try DISABLE_CERT_PINNING=true to confirm TLS vs app logic)',
            );
          }
          return pinned;
        };

        return client;
      },
    );
  }

  /// Same as [attach] but allows specifying a list of allowed hosts.
  /// Pins are only enforced for hosts in [pinnedHosts]; others use default TLS.
  static void attachForHosts(
    Dio dio, {
    required List<String> pinnedSha256Base64,
    required Set<String> pinnedHosts,
  }) {
    if (!kReleaseMode) {
      return;
    }
    if (AppConfig.disableCertPinning) {
      return;
    }
    if (pinnedSha256Base64.isEmpty) {
      throw StateError(
        'Certificate pinning requires at least one pin in release builds.',
      );
    }

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final context = SecurityContext(withTrustedRoots: false);
        final client = HttpClient(context: context);

        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Only enforce pinning for specified hosts
          if (!pinnedHosts.contains(host)) {
            wayoTlsDiagPrint(
              '[CertificatePinning] host not in pinnedHosts: $host (reject)',
            );
            // For non-pinned hosts, we can't easily "allow default validation"
            // since we have no trusted roots. In this case, caller should use
            // the regular attach() or not use this method.
            return false;
          }
          final sha = base64.encode(sha256.convert(cert.der).bytes);
          final ok = pinnedSha256Base64.contains(sha);
          if (!ok) {
            wayoTlsDiagPrint(
              '[CertificatePinning] REJECTED $host:$port peerSha256=$sha',
            );
          }
          return ok;
        };

        return client;
      },
    );
  }
}
