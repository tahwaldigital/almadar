import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
void _routeFromMessage(RemoteMessage message) {
  final postId = message.data['post_id']?.toString();
  final ctx = rootNavigatorKey.currentContext;
  if (postId != null && ctx != null && int.tryParse(postId) != null) {
    ctx.push('/article/$postId');
  }
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
    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen(_showNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);

    // Subscribe to the topics the WordPress plugin publishes to.
    final messaging = FirebaseMessaging.instance;
    await messaging.subscribeToTopic(ApiConstants.topicAll);
    await messaging.subscribeToTopic(ApiConstants.topicBreaking);

    // Register the device token with the backend (best-effort).
    try {
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
      // Backend may be unreachable or push disabled; ignore.
    }
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
