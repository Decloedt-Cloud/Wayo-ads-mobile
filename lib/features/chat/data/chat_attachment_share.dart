import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'chat_message_media.dart';

/// Shares chat media as a real file (image/PDF), not a plain URL string.
Future<bool> shareChatAttachmentAsFile({
  required String mediaUrl,
  Map<String, String>? httpHeaders,
  String? fileName,
  required bool isPdf,
}) async {
  final url = mediaUrl.trim();
  if (url.isEmpty) return false;

  if (kIsWeb) {
    try {
      await Share.share(url);
      return true;
    } catch (_) {
      return false;
    }
  }

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
      headers: const <String, dynamic>{'Accept': '*/*'},
    ),
  );

  List<int> bytes;
  try {
    final res = await dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: httpHeaders,
        followRedirects: true,
        maxRedirects: 12,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );
    bytes = res.data ?? const [];
  } catch (_) {
    return false;
  }
  if (bytes.isEmpty) return false;

  final name = _shareFilename(url, fileName, isPdf);
  final mime = _shareMimeType(name, isPdf);
  final dir = await getTemporaryDirectory();
  final safeName = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final file = File('${dir.path}/wayo_share_$safeName');
  await file.writeAsBytes(bytes, flush: true);

  try {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mime, name: safeName)],
    );
    return true;
  } catch (_) {
    return false;
  }
}

String _shareFilename(String url, String? fileName, bool isPdf) {
  final fromMsg = fileName?.trim();
  if (fromMsg != null && fromMsg.isNotEmpty && fromMsg.contains('.')) {
    return fromMsg;
  }
  final fromUrl = filenameFromMediaReference(url);
  if (fromUrl.contains('.')) return fromUrl;
  return isPdf ? 'document.pdf' : 'photo.jpg';
}

String _shareMimeType(String filename, bool isPdf) {
  if (isPdf) return 'application/pdf';
  return switch (extensionFromFilename(filename)) {
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'bmp' => 'image/bmp',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'image/jpeg',
  };
}
