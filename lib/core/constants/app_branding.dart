import '../network/api_hosts.dart';

class AppBranding {
  AppBranding._();

  /// Primary brand logo (wordmark), loaded from whichever domain is live so it
  /// keeps showing when the site moves.
  static String get logoUrl => ApiHosts.instance.url(
      '/wp-content/uploads/2025/11/%D8%A7%D9%84%D9%85%D8%AF%D8%A7%D8%B1-%D9%86%D9%8A%D9%88%D8%B2-10.webp');

  /// Natural aspect ratio of [logoUrl] (width / height = 400 / 120).
  static const double logoAspect = 400 / 120;

  static const String appName = 'المدار الإخبارية';
  static const String tagline = 'الحقيقة من كافة الزوايا';
}
