import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'providers.dart';

/// حالة توفّر التطبيق عند بدء التشغيل.
enum AppStatus {
  /// جارٍ فحص الاتصال بالموقع.
  checking,

  /// كل شيء يعمل — يُعرض التطبيق.
  available,

  /// الموقع فعّل وضع الصيانة/التحديث (عَلَم من الخادم).
  maintenance,

  /// تعذّر الوصول إلى الموقع (الخادم متوقف أو تحت التحديث).
  unreachable,

  /// لا يوجد اتصال بالإنترنت على الجهاز.
  offline,

  /// إصدار التطبيق أقدم من الحد الأدنى الذي يفرضه الخادم.
  updateRequired,
}

/// بيانات التحديث الإجباري القادمة من الخادم.
class ForceUpdateInfo {
  final String storeUrl;
  final String message;
  const ForceUpdateInfo({this.storeUrl = '', this.message = ''});
}

/// يفحص إمكانية الوصول إلى موقع المدار عند الإقلاع، ويكشف وضع الصيانة إن
/// أعلنه الخادم عبر عَلَم في نقطة `config`. يوفّر [recheck] لزر "إعادة المحاولة".
class AppStatusNotifier extends StateNotifier<AppStatus> {
  AppStatusNotifier(this._ref) : super(AppStatus.checking) {
    check();
  }

  final Ref _ref;

  static bool _flag(dynamic v) =>
      v == true || v == 1 || v == '1' || v == 'true';

  /// رسالة الصيانة القادمة من الخادم (إن وُجدت) لعرضها في شاشة التحديث.
  static String maintenanceMessage = '';

  static bool _isMaintenance(Map<String, dynamic> config) {
    // البنية الفعلية من الخادم: maintenance: { enabled: bool, message: string }
    final m = config['maintenance'];
    if (m is Map) {
      maintenanceMessage = (m['message'] ?? '').toString();
      if (_flag(m['enabled'])) return true;
    }
    // توافق مع صيغ بديلة (عَلَم مباشر).
    if (_flag(config['maintenance']) ||
        _flag(config['app_maintenance']) ||
        _flag(config['is_maintenance'])) {
      return true;
    }
    return false;
  }

  /// معلومات التحديث الإجباري (تُملأ عند [AppStatus.updateRequired]).
  static ForceUpdateInfo forceUpdate = const ForceUpdateInfo();

  /// يقارن نسختين بصيغة "1.2.3". يعيد سالبًا إذا كانت [a] أقدم من [b].
  static int _compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split(RegExp(r'[+\-]'))
        .first
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    final pa = parts(a);
    final pb = parts(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x - y;
    }
    return 0;
  }

  /// هل الإصدار الحالي أقدم من الحد الأدنى الذي يفرضه الخادم؟
  static Future<bool> _needsForceUpdate(Map<String, dynamic> config) async {
    final v = config['version'];
    if (v is! Map) return false;
    final isIOS = Platform.isIOS;
    // رابط المتجر يُختار حسب النظام: آيفون → App Store، أندرويد → Google Play.
    final storeUrl =
        (isIOS ? v['update_url_ios'] : v['update_url_android'])?.toString() ?? '';
    final message = (v['force_message'] ?? '').toString();

    // 1) مفتاح "طلب التحديث الآن" من لوحة التحكم — يفرض التحديث على كل المستخدمين.
    if (_flag(v['force_update'])) {
      forceUpdate = ForceUpdateInfo(storeUrl: storeUrl, message: message);
      return true;
    }

    // 2) بوابة حسب الحد الأدنى للإصدار المدعوم لكل منصة.
    final min = (isIOS ? v['min_ios'] : v['min_android'])?.toString() ?? '';
    if (min.trim().isEmpty) return false;
    final current = (await PackageInfo.fromPlatform()).version;
    if (current.trim().isEmpty) return false;
    if (_compareVersions(current, min) >= 0) return false;
    forceUpdate = ForceUpdateInfo(storeUrl: storeUrl, message: message);
    return true;
  }

  Future<void> check() async {
    state = AppStatus.checking;
    try {
      final config = await _ref
          .read(contentRemoteDataSourceProvider)
          .getConfig()
          // مهلة قصيرة: الإقلاع يجب ألا يُحجب طويلًا على فحص الشبكة.
          .timeout(const Duration(seconds: 4));
      if (_isMaintenance(config)) {
        state = AppStatus.maintenance;
        return;
      }
      if (await _needsForceUpdate(config)) {
        state = AppStatus.updateRequired;
        return;
      }
      state = AppStatus.available;
    } catch (_) {
      // فشل الوصول: ميّز بين انقطاع الإنترنت وتوقّف الموقع لرسالة أدق.
      try {
        final conn = await Connectivity().checkConnectivity();
        final hasNet = conn.any((c) => c != ConnectivityResult.none);
        state = hasNet ? AppStatus.unreachable : AppStatus.offline;
      } catch (_) {
        state = AppStatus.unreachable;
      }
    }
  }

  /// إعادة الفحص (زر "إعادة المحاولة").
  Future<void> recheck() => check();
}

final appStatusProvider =
    StateNotifierProvider<AppStatusNotifier, AppStatus>((ref) {
  return AppStatusNotifier(ref);
});
