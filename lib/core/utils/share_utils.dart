import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/contact_info.dart';

/// أدوات مشاركة التطبيق مع الآخرين.
class ShareUtils {
  ShareUtils._();

  /// يحسب مستطيل الأصل لورقة المشاركة.
  ///
  /// إلزامي على iOS: بدونه تنهار الورقة على الآيباد (popover بلا مرساة) وكذلك
  /// على الآيفون منذ iOS 26. لذلك لا يُعاد null أبدًا — إن تعذّر اشتقاق المستطيل
  /// من الودجت نرجع مستطيلًا في منتصف الشاشة كحل بديل مضمون.
  static Rect _originFrom(BuildContext context) {
    final ro = context.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      return ro.localToGlobal(Offset.zero) & ro.size;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
  }

  /// يفتح ورقة المشاركة الخاصة بالنظام.
  ///
  /// يعيد true عند نجاح فتح الورقة. عند الفشل يعرض تنبيهًا للمستخدم بدل
  /// الصمت التام الذي يبدو وكأن الزر لا يعمل.
  static Future<bool> share(
    BuildContext context,
    String text, {
    String? subject,
  }) async {
    if (text.trim().isEmpty) {
      debugPrint('[share] تم التجاهل: النص المطلوب مشاركته فارغ');
      _notify(context, 'لا يوجد رابط متاح لمشاركة هذا الخبر');
      return false;
    }

    final origin = _originFrom(context);
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
      );
      return true;
    } catch (e) {
      debugPrint('[share] فشلت المشاركة: $e');
      if (context.mounted) {
        _notify(context, 'تعذّرت المشاركة، حاول مرة أخرى');
      }
      return false;
    }
  }

  /// يبني نص دعوة لتحميل التطبيق ويفتح ورقة المشاركة الخاصة بالنظام.
  ///
  /// يستخدم روابط المتجر إن كانت متوفرة، وإلا يشارك رابط الموقع الرسمي.
  static Future<bool> shareApp(BuildContext context) async {
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

    return share(
      context,
      buffer.toString().trim(),
      subject: ContactInfo.publisher,
    );
  }

  static void _notify(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
