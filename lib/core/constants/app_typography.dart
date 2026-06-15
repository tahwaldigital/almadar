import 'package:flutter/material.dart';

/// السلّم الطباعي للتطبيق — خط Tajawal العربي (الأوزان المضمّنة: 400/500/700).
/// قاعدة عربية مهمة: لا نستخدم letterSpacing مع النص العربي لأنه يكسر وصلات الحروف.
class AppTypography {
  AppTypography._();

  // أسماء العائلات (كلها Tajawal — مُبقاة للتوافق مع بقية الكود).
  static const String rubik = 'Tajawal';
  static const String workSans = 'Tajawal';
  static const String ibmPlexSans = 'Tajawal';

  static const String _f = 'Tajawal';

  // Display / Headlines
  static const TextStyle displayLg = TextStyle(
    fontFamily: _f,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: _f,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.30,
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: _f,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.40,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: _f,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  // Body (قراءة مريحة بارتفاع سطر سخي)
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _f,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.90,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _f,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.70,
  );

  // Labels (بدون letterSpacing)
  static const TextStyle labelMd = TextStyle(
    fontFamily: _f,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.40,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: _f,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );
}
