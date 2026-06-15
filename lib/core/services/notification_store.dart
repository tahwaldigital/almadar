import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local store for received push notifications so the app can show
/// a notifications center. Persisted in SharedPreferences (capped to 50).
class NotificationStore {
  static const _key = 'received_notifications';
  static const _max = 50;

  static Future<void> add({
    required String title,
    String body = '',
    String? postId,
    String? image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _read(prefs);
    list.insert(0, {
      'title': title,
      'body': body,
      'post_id': postId,
      'image': image,
      'time': DateTime.now().toIso8601String(),
    });
    final trimmed = list.take(_max).toList();
    await prefs.setString(_key, jsonEncode(trimmed));
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static List<Map<String, dynamic>> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}
