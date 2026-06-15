import 'package:flutter/material.dart';

class ColorUtils {
  ColorUtils._();

  /// Parses "#RRGGBB" / "#AARRGGBB" / "RRGGBB" into a [Color].
  /// Falls back to [fallback] on any malformed input.
  static Color fromHex(String? hex, {Color fallback = const Color(0xFF9D4300)}) {
    if (hex == null) return fallback;
    var value = hex.trim().replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return fallback;
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
