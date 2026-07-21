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

Future<void> _showNotification(RemoteMessage message) async {
  const androidDetails = AndroidNotificationDetails(
    'almadar_channel',
    'المدار الإخبارية',
    channelDescription: 'إشعارات الأخبار العاجلة',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  await _localNotifications.show(
    message.hashCode,
    message.notification?.title ?? 'المدار الإخبارية',
    message.notification?.body ?? '',
    details,
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
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.subscribeToTopic(ApiConstants.topicAll);
    await messaging.subscribeToTopic(ApiConstants.topicBreaking);
    final fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      await DioClient().post(
        ApiConstants.devicesRegister,
        data: {
          'token': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'topics': [ApiConstants.topicAll, ApiConstants.topicBreaking],
          'lang': 'ar',
        },
      );
    }
  } catch (_) {
    // Backend unreachable or push disabled; ignore.
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

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    FirebaseMessaging.onMessage.listen(_showNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);

    // Cold start: the app was launched by tapping a notification.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _routeFromMessage(initialMessage);
    }

    // Fire-and-forget: never block startup on network.
    unawaited(_registerForPush());
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AlmadarApp(),
    ),
  );
}
