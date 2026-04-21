import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Local JSON cache with TTL for dashboard SWR (Hive).
abstract final class DashboardHiveStore {
  static const _ttl = Duration(minutes: 5);
  static const _boxName = 'wayo_dashboard';
  static Box<String>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  static String? readFresh(String key) {
    final b = _box;
    if (b == null) {
      return null;
    }
    final raw = b.get(key);
    if (raw == null) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse(map['at'] as String? ?? '');
      if (at == null || DateTime.now().difference(at) > _ttl) {
        return null;
      }
      return map['payload'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, String payloadJson) async {
    final b = _box;
    if (b == null) {
      return;
    }
    final envelope = jsonEncode({
      'at': DateTime.now().toIso8601String(),
      'payload': payloadJson,
    });
    await b.put(key, envelope);
  }

  /// Clears all dashboard SWR entries (e.g. after login / logout / account switch).
  static Future<void> clearAll() async {
    final b = _box;
    if (b == null) {
      return;
    }
    await b.clear();
  }
}
