import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayoadsgo/features/superadmin/data/superadmin_ops_remote.dart';

typedef _Handler = Future<ResponseBody> Function(
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

ResponseBody _bytes(List<int> data, {int status = 200}) {
  return ResponseBody.fromBytes(
    data,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/zip'],
    },
  );
}

Dio _newDio() {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
  return dio;
}

void main() {
  group('SuperadminOpsRemote.hardDeleteUser', () {
    test('DELETEs userById and succeeds on {ok:true}', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'DELETE');
        expect(options.path, contains('admin/users/user_123'));
        return _json({'ok': true});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      await remote.hardDeleteUser('user_123');

      expect(adapter.requests, hasLength(1));
    });

    test('throws StateError when server does not confirm ok:true', () async {
      final adapter = _RecordingAdapter((_, __) async {
        return _json({'error': 'Cannot hard-delete your own account'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      expect(
        () => remote.hardDeleteUser('self_id'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SuperadminOpsRemote.updateStripeSettings', () {
    test('PUTs mode + only provided secret fields, parses bundle response', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'PUT');
        expect(options.path, contains('stripe-settings'));
        final data = options.data as Map;
        expect(data['mode'], 'TEST');
        expect(data['secretKey'], 'sk_test_123');
        expect(data.containsKey('publishableKey'), isFalse);
        expect(data.containsKey('webhookSecret'), isFalse);
        return _json({
          'success': true,
          'activeMode': 'TEST',
          'settings': {
            'mode': 'TEST',
            'secretKeyMasked': 'sk_t***123',
          },
          'bundle': {
            'TEST': {
              'mode': 'TEST',
              'secretKeyMasked': 'sk_t***123',
            },
            'LIVE': {
              'mode': 'LIVE',
              'secretKeyMasked': null,
            },
          },
        });
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final status = await remote.updateStripeSettings(
        mode: 'TEST',
        secretKey: 'sk_test_123',
      );

      expect(status.activeMode, 'TEST');
      expect(status.test.secretKeyMasked, 'sk_t***123');
      expect(status.live.secretKeyMasked, isNull);
      expect(adapter.requests, hasLength(1));
    });

    test('throws StateError on API error', () async {
      final adapter = _RecordingAdapter((_, __) async {
        return _json({'error': 'Secret key is required for initial configuration'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      expect(
        () => remote.updateStripeSettings(mode: 'LIVE'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SuperadminOpsRemote.revealStripeSecret', () {
    test('POSTs mode/field/password and returns the plaintext value', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('stripe-settings/reveal'));
        final data = options.data as Map;
        expect(data['mode'], 'LIVE');
        expect(data['field'], 'secretKey');
        expect(data['password'], 'correct-password');
        return _json({'value': 'sk_live_super_secret'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final value = await remote.revealStripeSecret(
        mode: 'LIVE',
        field: 'secretKey',
        password: 'correct-password',
      );

      expect(value, 'sk_live_super_secret');
    });
  });

  group('SuperadminOpsRemote.updateEmailSettings', () {
    test('always sends password and omits empty optional fields', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'PUT');
        expect(options.path, contains('email-settings'));
        final data = options.data as Map;
        expect(data['host'], 'smtp.example.com');
        expect(data['port'], 587);
        expect(data['password'], 'smtp-pass');
        expect(data.containsKey('fromName'), isFalse);
        return _json({
          'success': true,
          'settings': {
            'host': 'smtp.example.com',
            'port': 587,
            'secure': true,
            'fromEmail': 'noreply@example.com',
            'isEnabled': true,
          },
        });
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final settings = await remote.updateEmailSettings(
        host: 'smtp.example.com',
        port: 587,
        secure: true,
        fromEmail: 'noreply@example.com',
        isEnabled: true,
        password: 'smtp-pass',
      );

      expect(settings.host, 'smtp.example.com');
      expect(settings.isEnabled, isTrue);
    });
  });

  group('SuperadminOpsRemote.testSmtpEmail', () {
    test('POSTs email and returns success result', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('email-settings/test-email'));
        final data = options.data as Map;
        expect(data['email'], 'qa@example.com');
        return _json({'success': true, 'message': 'Test email sent successfully to qa@example.com'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final result = await remote.testSmtpEmail(email: 'qa@example.com');

      expect(result.success, isTrue);
      expect(result.message, contains('qa@example.com'));
    });
  });

  group('SuperadminOpsRemote.sendTestEmailTemplate', () {
    test('POSTs to/templateName and returns success result', () async {
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('emails/send-test'));
        final data = options.data as Map;
        expect(data['to'], 'qa@example.com');
        expect(data['templateName'], 'auth.verify_code');
        return _json({'success': true, 'message': 'Test email sent to qa@example.com'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final result = await remote.sendTestEmailTemplate(
        to: 'qa@example.com',
        templateName: 'auth.verify_code',
      );

      expect(result.success, isTrue);
    });

    test('surfaces failure message when server returns success:false', () async {
      final adapter = _RecordingAdapter((_, __) async {
        return _json({'error': 'SMTP send failed — check Email Settings'});
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final result = await remote.sendTestEmailTemplate(
        to: 'qa@example.com',
        templateName: 'auth.verify_code',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('SMTP send failed'));
    });
  });

  group('SuperadminOpsRemote ZIP downloads', () {
    test('downloadAdminInvoicesZip POSTs ids/locale and returns raw bytes', () async {
      final zipBytes = <int>[0x50, 0x4B, 0x03, 0x04];
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('invoices/zip'));
        final data = options.data as Map;
        expect(data['ids'], ['inv_1', 'inv_2']);
        expect(data['locale'], 'en');
        return _bytes(zipBytes);
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final result = await remote.downloadAdminInvoicesZip(['inv_1', 'inv_2']);

      expect(result, Uint8List.fromList(zipBytes));
    });

    test('downloadAdminPaymentStatementsZip POSTs ids/locale and returns raw bytes', () async {
      final zipBytes = <int>[0x50, 0x4B, 0x03, 0x04, 0x05];
      final adapter = _RecordingAdapter((options, _) async {
        expect(options.method, 'POST');
        expect(options.path, contains('payment-statements/zip'));
        final data = options.data as Map;
        expect(data['ids'], ['stmt_1']);
        return _bytes(zipBytes);
      });
      final dio = _newDio()..httpClientAdapter = adapter;
      final remote = SuperadminOpsRemote(dio);

      final result = await remote.downloadAdminPaymentStatementsZip(['stmt_1']);

      expect(result, Uint8List.fromList(zipBytes));
    });
  });
}
