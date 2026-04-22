import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/auth_runtime_config.dart';
import '../network/scrubber.dart';

/// Applies Wayo privacy defaults and scrubbing to [SentryFlutterOptions].
void applySentryFlutterOptions(SentryFlutterOptions o) {
  final r = AuthRuntimeConfig.instance;
  o.dsn = r.effectiveSentryDsn;
  o.environment = r.effectiveSentryEnv;
  o.release = r.effectiveAppRelease;
  o.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
  o.attachScreenshot = false;
  o.sendDefaultPii = false;
  o.beforeSend = (SentryEvent event, Hint hint) {
    final req = event.request;
    // ignore: deprecated_member_use
    final scrubbedExtra = _scrubExtra(event.extra);
    if (req == null) {
      // ignore: deprecated_member_use
      return event.copyWith(extra: scrubbedExtra);
    }
    final headers = scrubToStringHeaders(
      scrub(Map<String, dynamic>.from(req.headers)),
    );
    final data = _scrubRequestPayload(req.data);
    return event.copyWith(
      request: req.copyWith(headers: headers, data: data),
      // ignore: deprecated_member_use
      extra: scrubbedExtra,
    );
  };
}

Map<String, dynamic>? _scrubExtra(Map<String, dynamic>? extra) {
  if (extra == null || extra.isEmpty) {
    return extra;
  }
  return scrub(extra);
}

dynamic _scrubRequestPayload(dynamic data) {
  if (data is Map) {
    return scrub(
      Map<String, dynamic>.from(data.map((k, dynamic v) => MapEntry('$k', v))),
    );
  }
  return data;
}
