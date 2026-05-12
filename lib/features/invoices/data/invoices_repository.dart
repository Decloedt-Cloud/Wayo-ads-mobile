import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../../../core/network/wayo_ads_dio.dart';
import '../domain/invoices_page.dart';
import 'invoices_remote_datasource.dart';

final invoicesRemoteProvider = Provider<InvoicesRemote>((ref) {
  return InvoicesRemoteDatasource(ref.watch(wayoAdsDioProvider));
});

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository(ref.watch(invoicesRemoteProvider));
});

final class InvoicesRepository {
  InvoicesRepository(this._remote);

  final InvoicesRemote _remote;

  Future<InvoicesPage> loadAdvertiserPage({required int page}) =>
      _remote.fetchAdvertiserPage(page: page);

  Future<InvoicesPage> loadCreatorPage({required int page}) =>
      _remote.fetchCreatorPage(page: page);

  Future<Uint8List> downloadPdf(
    String invoiceId, {
    void Function(int received, int total)? onProgress,
  }) => _remote.fetchInvoicePdf(invoiceId, onProgress: onProgress);

  /// Normalises low-level [DioException] / network glitches into the typed
  /// [AuthException] tree, so screens can render proper i18n error states.
  ///
  /// Prefer reading JSON `error` / `message` from the response body so the
  /// Invoices error UI and [kDebugMode] logs show the real server/proxy reason.
  static AuthException mapError(Object e) {
    if (e is AuthException) return e;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return NetworkException(
          'Network error (${e.type.name}). Check connectivity and '
          'WAYO_ADS_API_BASE_URL.',
        );
      }
      if (e.type == DioExceptionType.badCertificate) {
        return const ServerException(
          'TLS certificate rejected (pinning). For release builds verify '
          'CERT_PIN_* matches your Wayo-ads host, or use '
          'DISABLE_CERT_PINNING=true temporarily to confirm.',
        );
      }
      final code = e.response?.statusCode;
      final data = e.response?.data;
      var msg = e.message ?? 'Request failed';

      if (data is Map) {
        final err = data['error'] ?? data['message'];
        if (err is String && err.trim().isNotEmpty) {
          msg = err.trim();
        } else if (err != null) {
          msg = err.toString();
        }
      } else if (data is String) {
        final s = data.trim();
        final lower = s.toLowerCase();
        if (lower.contains('<!doctype') || lower.contains('<html')) {
          final wayoHandler = e.response?.headers.map['x-wayo-handler']?.first;
          final hasNextHandler = wayoHandler == 'invoices-list';
          msg =
              'HTTP $code: réponse HTML au lieu du JSON API Wayo-ads. '
              'La requête n’atteint probablement pas le route handler Next.js '
              'sur cet hôte (mauvaise origine, redirection qui supprime '
              'Authorization: Bearer, WAF / protection Vercel ou Cloudflare, '
              'ou confondre Auth Laravel avec WAYO_ADS_API_BASE_URL). '
              '${hasNextHandler ? '' : 'Absence de l’en-tête X-Wayo-Handler: invoices-list — ce n’est presque pas la route Next déployée. '}'
              'Vérifiez: curl -sI -H "Authorization: Bearer <token>" '
              '<WAYO_ADS>/api/invoices → doit contenir X-Wayo-Handler: invoices-list. '
              'Sur Vercel (ads), définissez AUTH_API_URL pour valider le Bearer mobile.';
        } else if (s.length <= 400) {
          msg = s;
        }
      }

      final path = e.requestOptions.uri.path;
      final method = e.requestOptions.method;
      return ServerException('$msg  [$method $path HTTP ${code ?? '?'}]', code);
    }
    if (e is FormatException) {
      return ServerException('Invalid response (not JSON): $e');
    }
    return ServerException('$e');
  }
}
