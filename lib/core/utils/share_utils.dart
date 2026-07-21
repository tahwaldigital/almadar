import 'package:share_plus/share_plus.dart';

import '../constants/contact_info.dart';

/// أدوات مشاركة التطبيق مع الآخرين.
class ShareUtils {
  ShareUtils._();

  /// يبني نص دعوة لتحميل التطبيق ويفتح ورقة المشاركة الخاصة بالنظام.
  ///
  /// يستخدم روابط المتجر إن كانت متوفرة، وإلا يشارك رابط الموقع الرسمي.
  static Future<void> shareApp() async {
    final buffer = StringBuffer()
      ..writeln('حمّل تطبيق ${ContactInfo.publisher} وتابع آخر الأخبار العاجلة أولًا بأول:')
      ..writeln();

    if (ContactInfo.androidStoreUrl.isNotEmpty) {
      buffer.writeln('📱 أندرويد: ${ContactInfo.androidStoreUrl}');
    }
    if (ContactInfo.iosStoreUrl.isNotEmpty) {
      buffer.writeln('🍏 آيفون: ${ContactInfo.iosStoreUrl}');
    }
    // يُضاف الموقع دائمًا ما لم يتوفر رابطا المتجرين معًا، حتى لا يصل مستخدم
    // أندرويد رابط App Store وحده بلا بديل يفتحه.
    final bothStores = ContactInfo.androidStoreUrl.isNotEmpty &&
        ContactInfo.iosStoreUrl.isNotEmpty;
    if (!bothStores && ContactInfo.website.isNotEmpty) {
      buffer.writeln('🌐 ${ContactInfo.website}');
    }

    await Share.share(
      buffer.toString().trim(),
      subject: ContactInfo.publisher,
    );
  }
}
