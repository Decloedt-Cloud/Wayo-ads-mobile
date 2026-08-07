import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/core/errors/auth_exceptions.dart';
import 'package:wayoadsgo/features/notification_prefs/data/notification_prefs_remote.dart';
import 'package:wayoadsgo/features/notification_prefs/domain/notification_preferences.dart';

typedef _Handler =
    Future<ResponseBody> Function(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
    );

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._handler);

  final _Handler _handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  group('NotificationPrefsRemote', () {
    test('fetch maps preferences payload', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'GET');
        expect(options.path, contains('notifications/preferences'));
        return _json({
          'allowInApp': true,
          'allowEmail': false,
          'allowSound': true,
          'allowBrowserPush': false,
          'categories': {
            'video': {'inApp': true, 'email': false},
          },
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = NotificationPrefsRemote(dio);

      final snap = await remote.fetch();
      expect(snap.allowEmail, isFalse);
      expect(snap.categories[NotificationPrefCategory.video]?.email, isFalse);
      expect(adapter.requests, hasLength(1));
    });

    test('patchCategory sends category channel enabled', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'PATCH');
        expect(options.path, contains('notifications/preferences'));
        final data = options.data as Map;
        expect(data['category'], 'applications');
        expect(data['channel'], 'inApp');
        expect(data['enabled'], isFalse);
        return _json({
          'allowInApp': true,
          'allowEmail': true,
          'allowSound': true,
          'allowBrowserPush': false,
          'categories': {
            'applications': {'inApp': false, 'email': true},
          },
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = NotificationPrefsRemote(dio);

      final snap = await remote.patchCategory(
        category: NotificationPrefCategory.applications,
        channel: 'inApp',
        enabled: false,
      );
      expect(
        snap.categories[NotificationPrefCategory.applications]?.inApp,
        isFalse,
      );
    });

    test('401 maps to SessionInvalidException', () async {
      final adapter = _RecordingAdapter((options, _) async {
        return _json({}, status: 401);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.httpClientAdapter = adapter;
      final remote = NotificationPrefsRemote(dio);
      expect(remote.fetch(), throwsA(isA<SessionInvalidException>()));
    });
  });
}
