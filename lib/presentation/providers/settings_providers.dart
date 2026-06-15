import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import 'providers.dart';

// ── Notification topic preferences ────────────────────────────────────────────
class NotificationPrefs {
  final bool breaking;
  final bool daily;
  const NotificationPrefs({this.breaking = true, this.daily = true});

  NotificationPrefs copyWith({bool? breaking, bool? daily}) =>
      NotificationPrefs(breaking: breaking ?? this.breaking, daily: daily ?? this.daily);
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier(this._prefs)
      : super(NotificationPrefs(
          breaking: _prefs.getBool(_kBreaking) ?? true,
          daily: _prefs.getBool(_kDaily) ?? true,
        ));

  static const _kBreaking = 'notif_breaking';
  static const _kDaily = 'notif_daily';

  final SharedPreferences _prefs;

  Future<void> setBreaking(bool value) async {
    state = state.copyWith(breaking: value);
    await _prefs.setBool(_kBreaking, value);
    await _toggleTopic(ApiConstants.topicBreaking, value);
  }

  Future<void> setDaily(bool value) async {
    state = state.copyWith(daily: value);
    await _prefs.setBool(_kDaily, value);
    await _toggleTopic(ApiConstants.topicAll, value);
  }

  Future<void> _toggleTopic(String topic, bool subscribe) async {
    try {
      final fm = FirebaseMessaging.instance;
      if (subscribe) {
        await fm.subscribeToTopic(topic);
      } else {
        await fm.unsubscribeFromTopic(topic);
      }
    } catch (_) {
      // Firebase may be unavailable in dev; ignore.
    }
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>((ref) {
  return NotificationPrefsNotifier(ref.read(sharedPreferencesProvider));
});

// ── Global font scale (reading comfort) ───────────────────────────────────────
class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier(this._prefs) : super(_prefs.getDouble(_key) ?? 1.0);

  static const _key = 'font_scale';
  final SharedPreferences _prefs;

  Future<void> set(double value) async {
    state = value;
    await _prefs.setDouble(_key, value);
  }
}

final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, double>((ref) {
  return FontScaleNotifier(ref.read(sharedPreferencesProvider));
});
