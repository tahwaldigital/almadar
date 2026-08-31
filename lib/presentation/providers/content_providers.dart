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

// ── Received push notifications (local store) ──────────────────────────────────
final receivedNotificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return NotificationStore.getAll();
});
