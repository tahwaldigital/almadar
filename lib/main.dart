import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/network/dio_client.dart';
import 'core/services/notification_store.dart';
import 'presentation/providers/providers.dart';
import 'presentation/router/app_router.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showNotification(message);
}

const _notifDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    'almadar_channel',
    'المدار الإخبارية',
    channelDescription: 'إشعارات الأخبار العاجلة',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  ),
);

Future<void> _showNotification(RemoteMessage message) async {
  await _localNotifications.show(
    message.hashCode,
    message.notification?.title ?? 'المدار الإخبارية',
    message.notification?.body ?? '',
    _notifDetails,
    // نمرّر معرّف الخبر ليُفتح المقال عند النقر على الإشعار المعروض محليًا.
    payload: message.data['post_id']?.toString(),
  );

  // Persist for the in-app notifications center.
  try {
    await NotificationStore.add(
      title: message.notification?.title ?? 'المدار الإخبارية',
      body: message.notification?.body ?? '',
      postId: message.data['post_id']?.toString(),
      image: message.data['image']?.toString(),
    );
  } catch (_) {}
}

/// Deep-link into an article when a push notification is tapped.
///
/// The router may not be mounted yet (cold start from a notification), so the
/// route is retried on later frames instead of being dropped.
void _routeFromMessage(RemoteMessage message) {
  final postId = message.data['post_id']?.toString();
  if (postId == null || int.tryParse(postId) == null) return;
  _pushWhenReady('/article/$postId');
}

/// Tap on a locally-shown notification (foreground messages). The FCM
/// onMessageOpenedApp stream does NOT fire for these, so we route from payload.
void _onLocalNotificationTap(NotificationResponse response) {
  final postId = response.payload;
  if (postId != null && postId.isNotEmpty && int.tryParse(postId) != null) {
    _pushWhenReady('/article/$postId');
  }
}

/// Subscribe to topics and register the device token — best-effort and
/// deliberately NOT awaited before runApp, so a slow network never delays
/// app startup.
Future<void> _registerForPush() async {
  final messaging = FirebaseMessaging.instance;
  try {
    // على iOS لا يصدر FCM أي توكن (ولا يقبل الاشتراك في topics) قبل أن تسلّمنا
    // أبل رمز APNs، وهو يصل عبر الشبكة بعد الإقلاع بلحظات. بدون هذا الانتظار
    // ترمي getToken الخطأ [firebase_messaging/apns-token-not-set]. أندرويد لا
    // يمر بهذا الشرط إطلاقًا — وهذا سبب نجاحه وفشل iOS.
    if (Platform.isIOS) {
      String? apnsToken;
      for (var attempt = 0; attempt < 10; attempt++) {
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (apnsToken == null) {
        debugPrint('[push] تعذّر الحصول على رمز APNs — تم إلغاء التسجيل. '
            'تحقّق من تفعيل Push Notifications على معرّف التطبيق ومن رفع '
            'مفتاح APNs (.p8) في Firebase Console.');
        return;
      }
      debugPrint('[push] رمز APNs جاهز');
    }

    final fcmToken = await messaging.getToken();
    if (fcmToken == null) {
      debugPrint('[push] getToken أعاد null — لم يتم التسجيل');
      return;
    }
    debugPrint('[push] رمز FCM: $fcmToken');

    // الاشتراك في الـ topics بعد توفّر التوكن وليس قبله.
    await messaging.subscribeToTopic(ApiConstants.topicAll);
    await messaging.subscribeToTopic(ApiConstants.topicBreaking);

    await _sendTokenToServer(fcmToken);
  } catch (e) {
    debugPrint('[push] فشل تسجيل الإشعارات: $e');
  }
}

/// يرسل رمز الجهاز إلى الخادم. مفصولة عن [_registerForPush] لأن
/// onTokenRefresh يعيد استخدامها عند تجديد التوكن.
Future<void> _sendTokenToServer(String token) async {
  try {
    await DioClient().post(
      ApiConstants.devicesRegister,
      data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'topics': [ApiConstants.topicAll, ApiConstants.topicBreaking],
        'lang': 'ar',
      },
    );
    debugPrint('[push] تم تسجيل الجهاز على الخادم');
  } catch (e) {
    debugPrint('[push] تعذّر تسجيل الجهاز على الخادم: $e');
  }
}

/// إشعارات من الـAPI بدون Firebase: يجلب آخر العاجل/الجديد ويعرض إشعارًا محليًا
/// للعناصر الجديدة فقط. يُستدعى عند الإقلاع وعند كل استئناف للتطبيق.
Future<void> _checkApiNotifications() async {
  try {
    final res = await DioClient().get(
      ApiConstants.notificationsFeed,
      queryParameters: {'per_page': 10},
    );
    final data = res.data;
    final items = (data is Map &&
            data['data'] is Map &&
            (data['data'] as Map)['items'] is List)
        ? ((data['data'] as Map)['items'] as List)
        : const [];
    if (items.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    const key = 'notif_last_pushed';
    final last = prefs.getString(key) ?? '';
    final newest = (items.first['date'] ?? '').toString();

    // أول تشغيل: اضبط الأساس فقط دون إغراق المستخدم بإشعارات قديمة.
    if (last.isEmpty) {
      if (newest.isNotEmpty) await prefs.setString(key, newest);
      return;
    }

    final fresh = items
        .where((n) => (n['date'] ?? '').toString().compareTo(last) > 0)
        .toList();
    for (final n in fresh.take(3)) {
      final title = (n['title'] ?? 'المدار الإخبارية').toString();
      final body = (n['body'] ?? '').toString();
      final postId = n['post_id']?.toString();
      await _localNotifications.show(
        (postId ?? title).hashCode,
        title,
        body,
        _notifDetails,
        payload: postId,
      );
      try {
        await NotificationStore.add(
          title: title,
          body: body,
          postId: postId,
          image: n['image']?.toString(),
        );
      } catch (_) {}
    }
    if (newest.isNotEmpty) await prefs.setString(key, newest);
  } catch (_) {
    // شبكة غير متاحة أو خطأ خادم؛ تجاهل بهدوء.
  }
}

/// يعيد فحص إشعارات الـAPI عند عودة التطبيق للواجهة.
class _LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkApiNotifications());
    }
  }
}

void _pushWhenReady(String route, {int attempt = 0}) {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx != null) {
    ctx.push(route);
    return;
  }
  // Router not mounted yet — retry on the next frames (max ~5s).
  if (attempt >= 50) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      _pushWhenReady(route, attempt: attempt + 1);
    });
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  timeago.setLocaleMessages('ar', timeago.ArMessages());
  await initializeDateFormatting('ar', null);

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<dynamic>(ApiConstants.savedPostsBox),
    Hive.openBox<dynamic>(ApiConstants.cachedPostsBox),
  ]);

  final prefs = await SharedPreferences.getInstance();

  // Firebase (safe init — works without google-services.json during development)
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    // Firebase not configured yet
  }

  // إشعارات محلية: تُهيّأ دائمًا (تعمل حتى بدون Firebase — أساسية لـ iOS) وتطلب
  // إذن الإشعارات على iOS.
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onLocalNotificationTap,
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[push] إذن الإشعارات: ${settings.authorizationStatus}');

    // التطبيق يعرض إشعار المقدّمة بنفسه عبر _showNotification (إشعار محلي،
    // متطابق مع أندرويد). بدون تعطيل عرض FCM هنا يظهر إشعار مزدوج على iOS.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen(_showNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);

    // يتجدّد رمز الجهاز دوريًا (وعلى iOS قد يصل متأخرًا بعد رمز APNs)،
    // فنعيد إرساله للخادم بدل فقدان الجهاز من قائمة الإشعارات.
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToServer);

    // Cold start: the app was launched by tapping a notification.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _routeFromMessage(initialMessage);
    }

    // Fire-and-forget: never block startup on network.
    unawaited(_registerForPush());
  }

  // إشعارات من الـAPI (تعمل بدون Firebase، تشمل iOS): افحص عند الإقلاع + الاستئناف.
  WidgetsBinding.instance.addObserver(_LifecycleObserver());
  unawaited(_checkApiNotifications());

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AlmadarApp(),
    ),
  );
}
