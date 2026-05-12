import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/auth_exceptions.dart';
import '../domain/invoice.dart';
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

  /// Downloads the PDF, writes it to a temp file, and returns the file ready
  /// to be opened or shared. Throws [AuthException] on any failure.
  Future<File> downloadAndSave(
    Invoice invoice, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final bytes = await _repo.downloadPdf(invoice.id, onProgress: onProgress);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_filenameFor(invoice)}');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      throw InvoicesRepository.mapError(e);
    }
  }

  /// Opens the downloaded PDF with the OS default app.
  Future<void> open(File file) async {
    await OpenFilex.open(file.path, type: 'application/pdf');
  }

  /// Triggers the system share sheet with the PDF attached.
  Future<void> share(File file, {required String subject}) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: subject,
    );
  }
}

final invoicePdfServiceProvider = Provider<InvoicePdfService>((ref) {
  return InvoicePdfService(ref.watch(invoicesRepositoryProvider));
});
