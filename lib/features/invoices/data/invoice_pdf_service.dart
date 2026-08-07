import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../domain/invoice.dart';
import '../domain/invoice_pdf_locale.dart';
import 'invoices_repository.dart';

/// Stateless service responsible for downloading, saving, opening and sharing
/// invoice PDFs. Designed to be invoked from screens without holding state itself —
/// callers pass progress callbacks if they want a UI indicator.
final class InvoicePdfService {
  InvoicePdfService(this._repo);

  final InvoicesRepository _repo;

  /// Sanitises a filesystem-safe filename based on the invoice number.
  String _filenameFor(Invoice invoice) {
    final raw = invoice.invoiceNumber.isEmpty ? invoice.id : invoice.invoiceNumber;
    final clean = raw.replaceAll(RegExp(r'[^A-Za-z0-9\-_]'), '_');
    return 'invoice-$clean.pdf';
  }

  static bool _isCreatorPayoutDoc(Invoice invoice) {
    return invoice.roleType == InvoiceRoleType.creator &&
        (invoice.type == InvoiceType.payout ||
            invoice.type == InvoiceType.tokenPurchase);
  }

  String _zipFilenameFor(List<Invoice> invoices) {
    final stamp = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    if (invoices.isNotEmpty && _isCreatorPayoutDoc(invoices.first)) {
      return 'payouts_$stamp.zip';
    }
    return 'invoices_$stamp.zip';
  }

  /// Downloads the PDF, writes it to a temp file, and returns the file ready
  /// to be opened or shared. Throws [AuthException] on any failure.
  Future<File> downloadAndSave(
    Invoice invoice, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final locale = invoicePdfLocaleForApp();
      final bytes = _isCreatorPayoutDoc(invoice)
          ? await _repo.downloadPayoutPdf(
              invoice.invoiceNumber,
              locale: locale,
              onProgress: onProgress,
            )
          : await _repo.downloadPdf(
              invoice.id,
              locale: locale,
              onProgress: onProgress,
            );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_filenameFor(invoice)}');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      throw InvoicesRepository.mapError(e);
    }
  }

  /// Downloads a ZIP of PDFs for [invoices] (current page / selection), saves
  /// it under a temp path, and returns the file. Throws [AuthException] on failure.
  Future<File> downloadZipAndSave(
    List<Invoice> invoices, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final ids = invoices
          .map((e) => e.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      if (ids.isEmpty) {
        throw const FormatException('ZIP download: no invoice IDs');
      }

      final locale = invoicePdfLocaleForApp();
      final sample = invoices.first;
      final Uint8List bytes;
      if (_isCreatorPayoutDoc(sample)) {
        bytes = await _repo.downloadCreatorPayoutsZip(
          ids,
          locale: locale,
          onProgress: onProgress,
        );
      } else if (sample.roleType == InvoiceRoleType.creator) {
        bytes = await _repo.downloadCreatorInvoicesZip(
          ids,
          locale: locale,
          onProgress: onProgress,
        );
      } else {
        bytes = await _repo.downloadAdvertiserZip(
          ids,
          locale: locale,
          onProgress: onProgress,
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_zipFilenameFor(invoices)}');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      throw InvoicesRepository.mapError(e);
    }
  }

  /// Opens the downloaded PDF with the OS default app.
  Future<void> open(File file, {String type = 'application/pdf'}) async {
    await OpenFilex.open(file.path, type: type);
  }

  /// Triggers the system share sheet with the PDF attached.
  Future<void> share(
    File file, {
    required String subject,
    String mimeType = 'application/pdf',
  }) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: subject,
    );
  }
}

final invoicePdfServiceProvider = Provider<InvoicePdfService>((ref) {
  return InvoicePdfService(ref.watch(invoicesRepositoryProvider));
});
