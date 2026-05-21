import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';

import '../../../../i18n/strings.g.dart';
import 'chat_image_browser_download_stub.dart'
    if (dart.library.html) 'chat_image_browser_download_web.dart';
import 'gal_save_temp_io.dart' if (dart.library.html) 'gal_save_temp_stub.dart';

/// Opens a dark fullscreen viewer with pinch-zoom; top-right actions: download
/// (gallery on mobile/desktop, browser download on web), then close.
Future<void> openChatFullscreenImage(
  BuildContext context, {
  required String imageUrl,
  Map<String, String>? httpHeaders,
}) async {
  if (imageUrl.isEmpty) return;
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      fullscreenDialog: true,
      opaque: true,
      pageBuilder: (ctx, animation, secondaryAnimation) =>
          _ChatFullscreenImagePage(
            imageUrl: imageUrl,
            httpHeaders: httpHeaders,
          ),
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _ChatFullscreenImagePage extends StatefulWidget {
  const _ChatFullscreenImagePage({
    required this.imageUrl,
    this.httpHeaders,
  });

  final String imageUrl;
  final Map<String, String>? httpHeaders;

  @override
  State<_ChatFullscreenImagePage> createState() =>
      _ChatFullscreenImagePageState();
}

class _ChatFullscreenImagePageState extends State<_ChatFullscreenImagePage> {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  bool _saving = false;

  /// JPG / PNG / WebP / GIF magic bytes — extension + MIME for save / download filenames.
  String _inferImageExtension(List<int> head) {
    if (head.length < 12) return '.jpg';
    if (head[0] == 0xff && head[1] == 0xd8 && head[2] == 0xff) return '.jpg';
    if (head.length >= 8 &&
        head[0] == 0x89 &&
        head[1] == 0x50 &&
        head[2] == 0x4e &&
        head[3] == 0x47 &&
        head[4] == 0x0d &&
        head[5] == 0x0a &&
        head[6] == 0x1a &&
        head[7] == 0x0a) {
      return '.png';
    }
    if (head.length >= 6 &&
        head[0] == 0x47 &&
        head[1] == 0x49 &&
        head[2] == 0x46 &&
        head[3] == 0x38) {
      return '.gif';
    }
    if (head.length >= 12 &&
        head[0] == 0x52 &&
        head[1] == 0x49 &&
        head[2] == 0x46 &&
        head[3] == 0x46 &&
        head[8] == 0x57 &&
        head[9] == 0x45 &&
        head[10] == 0x42 &&
        head[11] == 0x50) {
      return '.webp';
    }
    return '.jpg';
  }

  String _mimeForExtension(String ext) {
    return switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  Uint8List _bytesFromDio(Response<List<int>> r) {
    final data = r.data;
    if (data == null || data.isEmpty) {
      throw StateError('empty image body');
    }
    return Uint8List.fromList(data);
  }

  Future<Uint8List> _fetchBytesWithDio() async {
    final url = widget.imageUrl;
    final auth = widget.httpHeaders;

    Future<Uint8List> get(Map<String, String>? hdr) async {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: hdr,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
          followRedirects: true,
          maxRedirects: 12,
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      return _bytesFromDio(response);
    }

    if (auth != null && auth.isNotEmpty) {
      try {
        return await get(auth);
      } on DioException catch (e) {
        final c = e.response?.statusCode;
        if (c != 401 && c != 403) rethrow;
      }
    }

    try {
      return await get(null);
    } on DioException catch (e2) {
      final c = e2.response?.statusCode;
      if (auth != null &&
          auth.isNotEmpty &&
          (c == 401 || c == 403 || c == null)) {
        return await get(auth);
      }
      rethrow;
    }
  }

  /// Reuse [DefaultCacheManager] (same URL key as thumbnails) then fall back to Dio.
  Future<Uint8List> _loadImageBytesReliable() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(
        widget.imageUrl,
        headers: widget.httpHeaders,
      );
      final raw = await file.readAsBytes();
      if (raw.isNotEmpty) {
        return raw;
      }
    } catch (_) {}
    return _fetchBytesWithDio();
  }

  Future<void> _persistToGalleryNative(Uint8List bytes) async {
    if (!mounted) return;
    final chat = context.t.chat;

    final has = await Gal.hasAccess(toAlbum: false);
    if (!mounted) return;

    final granted = has || await Gal.requestAccess(toAlbum: false);
    if (!mounted) return;

    if (!granted) {
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(chat.image_permission_denied)),
      );
      return;
    }

    final ext = _inferImageExtension(bytes);

    try {
      await Gal.putImageBytes(
        bytes,
        name: 'wayo_chat_${DateTime.now().millisecondsSinceEpoch}',
      );
    } on GalException catch (e) {
      if (e.type == GalExceptionType.notSupportedFormat ||
          e.type == GalExceptionType.unexpected) {
        // Temp file + Gal.putImage uses the file extension instead of MIME sniffing.
        await galPutImageViaTempFile(bytes, ext);
      } else {
        rethrow;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(chat.image_saved_to_gallery)),
    );
  }

  Future<void> _onDownloadTap() async {
    if (_saving || !mounted) return;

    final chatLoc = context.t.chat;
    setState(() => _saving = true);

    try {
      final bytes = await _loadImageBytesReliable();
      if (!mounted) return;

      if (kIsWeb) {
        final ext = _inferImageExtension(bytes);
        final mime = _mimeForExtension(ext);
        triggerBrowserImageDownload(
          bytes,
          mime,
          'wayo_chat_${DateTime.now().millisecondsSinceEpoch}$ext',
        );
        ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(chatLoc.image_saved_downloads_browser)),
        );
        return;
      }

      await _persistToGalleryNative(bytes);
    } on GalException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      final msg = e.type == GalExceptionType.accessDenied
          ? chatLoc.image_permission_denied
          : (kDebugMode
              ? '${chatLoc.image_download_failed} (${e.type.code})'
              : chatLoc.image_download_failed);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(chatLoc.image_download_failed)),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final maxPx =
        (MediaQuery.sizeOf(context).longestSide * dpr).round().clamp(1200, 4096);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.6,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    httpHeaders: widget.httpHeaders,
                    fit: BoxFit.contain,
                    fadeInDuration: Duration.zero,
                    memCacheWidth: maxPx,
                    memCacheHeight: maxPx,
                    placeholder: (context, url) => SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.35,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 56,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: t.chat.image_download_tooltip,
                      child: Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          onPressed: _saving ? null : _onDownloadTap,
                          icon: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.download_rounded,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: t.chat.image_close_tooltip,
                      child: Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
