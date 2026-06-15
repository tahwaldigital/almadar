import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import 'providers.dart';

final isDarkModeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier(this._prefs) : super(_prefs.getBool(ApiConstants.themeKey) ?? false);

  final SharedPreferences _prefs;

  void toggle() {
    state = !state;
    _prefs.setBool(ApiConstants.themeKey, state);
  }

  void setDark(bool value) {
    state = value;
    _prefs.setBool(ApiConstants.themeKey, value);
  }
}
