import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class AppDateUtils {
  AppDateUtils._();

  static String timeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return timeago.format(date, locale: 'ar');
    } catch (_) {
      return dateString;
    }
  }

  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  /// تاريخ ووقت النشر بصيغة مطلقة واضحة، مثل: "1 يوليو 2026 - 02:30 م".
  /// مطلوب لسياسة الأخبار في Google Play (إظهار وقت النشر لكل خبر).
  static String formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(date);
    } catch (_) {
      return dateString;
    }
  }
}
