import 'package:flutter/material.dart';

/// نظام ألوان محايد + برتقالي علامة وحيد (المرحلة 1 من تطوير التصميم).
/// أسطح رمادية محايدة دافئة قليلاً، حبر داكن عالي التباين، أكسنت برتقالي،
/// ورمادي ثانوي هادئ بدل الأزرق السابق. أسماء التوكنات مُبقاة كما هي.
class AppColors {
  AppColors._();

  // ── Primary (الأكسنت البرتقالي — لون العلامة الوحيد) ──
  static const Color primary = Color(0xFFB84A06); // برتقالي عميق للنص/الأيقونات
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFF0640C); // برتقالي حيّ للتعبئة/الشارات
  static const Color onPrimaryContainer = Color(0xFF4A1F00); // حبر داكن فوق البرتقالي
  static const Color inversePrimary = Color(0xFFFFB690); // برتقالي فاتح للوضع الداكن

  // ── Secondary (رمادي محايد هادئ) ──
  static const Color secondary = Color(0xFF5B6068);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFEDEDEA);
  static const Color onSecondaryContainer = Color(0xFF3A3F46);

  // ── Tertiary (من عائلة البرتقالي، نادر الاستخدام) ──
  static const Color tertiary = Color(0xFFB84A06);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFCE9DC);
  static const Color onTertiaryContainer = Color(0xFF7A3A00);

  // ── Surfaces (رمادي محايد فاتح) ──
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE7E7E3);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F6F4);
  static const Color surfaceContainer = Color(0xFFF1F0ED);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E4);
  static const Color surfaceContainerHighest = Color(0xFFE1E0DB);
  static const Color surfaceDark = Color(0xFF0B0E12); // خلفية الوضع الداكن (محايد)

  // ── On Surface (حبر) ──
  static const Color onSurface = Color(0xFF16181C); // حبر داكن عالي التباين
  static const Color onSurfaceVariant = Color(0xFF5B6068); // رمادي محايد (بدل البنّي)
  static const Color inverseSurface = Color(0xFF2A2D32);
  static const Color inverseOnSurface = Color(0xFFECEEF1); // نص الوضع الداكن (قرب الأبيض)

  // ── Outline ──
  static const Color outline = Color(0xFFC7C7C2);
  static const Color outlineVariant = Color(0xFFE5E4E0);

  // ── Background ──
  static const Color background = Color(0xFFFAFAF9);
  static const Color onBackground = Color(0xFF16181C);

  // ── Error ──
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // ── Status Colors ──
  static const Color breakingRed = Color(0xFFE11D48);
  static const Color liveGreen = Color(0xFF16A34A);

  // ── Misc ──
  static const Color surfaceTint = Color(0xFFB84A06);
  static const Color surfaceVariant = Color(0xFF9AA3AE); // يُستخدم كنص باهت في الوضع الداكن
}
