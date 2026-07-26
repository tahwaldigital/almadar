/// بيانات الاتصال الرسمية للمؤسسة الإخبارية.
///
/// مطلوبة لسياسة Google Play الخاصة بفئة News & Magazines: يجب أن تكون
/// معلومات الاتصال حقيقية وقابلة للتحقق. استبدل القيم أدناه بالقيم الرسمية
/// قبل رفع التطبيق. أي حقل يُترك فارغًا ('') يُخفى تلقائيًا من شاشة "اتصل بنا".
class ContactInfo {
  ContactInfo._();

  /// اسم المؤسسة/الناشر.
  static const String publisher = 'شبكة المدار الإخبارية';

  /// البريد الإلكتروني الرسمي (يُفتح عبر تطبيق البريد).
  static const String email = 'info@almadr-news.com';

  /// رقم الهاتف الرسمي بصيغة دولية.
  static const String phone = '+966549140787';

  /// رقم واتساب بصيغة دولية بدون + أو مسافات.
  static const String whatsapp = '966549140787';

  /// العنوان البريدي/الفيزيائي.
  static const String address = 'القطيف، المملكة العربية السعودية';

  /// الموقع الإلكتروني الرسمي.
  static const String website = 'https://www.almadr-news.com';

  // ── روابط التواصل الاجتماعي ──────────────────────────────────────────────
  // ضع رابط كل حساب رسمي للصحيفة. أي حقل يُترك فارغًا ('') يُخفى تلقائيًا من
  // شاشة "وسائل التواصل". استخدم روابط كاملة (تبدأ بـ https://).
  static const String facebook = '';
  static const String instagram = '';
  static const String x = ''; // إكس (تويتر سابقًا)
  static const String snapchat = '';
  static const String telegram = ''; // مثال: https://t.me/almadarnews
  static const String tiktok = '';
  static const String youtube = '';

  // ── مشاركة التطبيق ────────────────────────────────────────────────────────
  // روابط المتجر تُضاف بعد نشر التطبيق. طالما فارغة، يُشارَك رابط الموقع بدلًا منها.
  static const String androidStoreUrl = ''; // رابط Google Play
  static const String iosStoreUrl =
      'https://apps.apple.com/us/app/almadar-news/id6785792779'; // رابط App Store
}
