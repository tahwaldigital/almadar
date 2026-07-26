import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_store.dart';
import '../../domain/entities/article.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/page_entity.dart';
import 'providers.dart';

// ── Videos ────────────────────────────────────────────────────────────────────
final videosProvider = FutureProvider<List<Article>>((ref) async {
  return ref.read(contentRemoteDataSourceProvider).getVideos();
});

// ── Most viewed ───────────────────────────────────────────────────────────────
final mostViewedProvider = FutureProvider<List<Article>>((ref) async {
  return ref.read(contentRemoteDataSourceProvider).getMostViewed();
});

// ── Author ────────────────────────────────────────────────────────────────────
final authorProvider =
    FutureProvider.family<AuthorEntity, int>((ref, id) async {
  return ref.read(contentRemoteDataSourceProvider).getAuthor(id);
});

final authorPostsProvider =
    FutureProvider.family<List<Article>, int>((ref, id) async {
  return ref.read(contentRemoteDataSourceProvider).getAuthorPosts(id);
});

// ── Static pages ──────────────────────────────────────────────────────────────
final pageProvider = FutureProvider.family<PageEntity, int>((ref, id) async {
  return ref.read(contentRemoteDataSourceProvider).getPage(id);
});

// ── App config (dynamic branding / links / features) ──────────────────────────
final appConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(contentRemoteDataSourceProvider).getConfig();
});

// ── Notifications (API-based, no Firebase) ──────────────────────────────────────
// Merges any locally-received (FCM) notifications with the public API feed
// (active breaking + latest posts), deduped by post id and sorted newest first.
final receivedNotificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final out = <Map<String, dynamic>>[];
  final seen = <String>{};

  for (final n in await NotificationStore.getAll()) {
    final id = (n['post_id'] ?? '').toString();
    if (id.isNotEmpty && !seen.add(id)) continue;
    out.add({...n, 'date': n['date'] ?? n['time'] ?? ''});
  }

  try {
    final feed =
        await ref.read(contentRemoteDataSourceProvider).getNotificationsFeed();
    for (final n in feed) {
      final id = (n['post_id'] ?? '').toString();
      if (id.isNotEmpty && !seen.add(id)) continue;
      out.add(n);
    }
  } catch (_) {
    // Offline / API error: fall back to whatever local items we have.
  }

  out.sort((a, b) =>
      (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));
  return out;
});

const _kNotifLastSeen = 'notif_last_seen';

/// عدد الإشعارات الأحدث من آخر مرة فتح فيها المستخدم مركز الإشعارات (شارة).
final unreadNotificationsProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(receivedNotificationsProvider.future);
  final lastSeen =
      ref.read(sharedPreferencesProvider).getString(_kNotifLastSeen) ?? '';
  return items
      .where((n) => (n['date'] ?? '').toString().compareTo(lastSeen) > 0)
      .length;
});

/// علّم كل الإشعارات كمقروءة (يُستدعى عند فتح مركز الإشعارات).
Future<void> markNotificationsSeen(WidgetRef ref) async {
  final items = await ref.read(receivedNotificationsProvider.future);
  if (items.isEmpty) return;
  final newest = (items.first['date'] ?? '').toString();
  await ref.read(sharedPreferencesProvider).setString(_kNotifLastSeen, newest);
  ref.invalidate(unreadNotificationsProvider);
}
