import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/local/news_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/content_remote_datasource.dart';
import '../../data/datasources/remote/news_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/news_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/news_repository.dart';
import '../../domain/usecases/get_breaking_news.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_latest_news.dart';
import '../../domain/usecases/get_news_by_category.dart';
import '../../domain/usecases/get_related_posts.dart';
import '../../domain/usecases/get_trending_news.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/search_news.dart';
import '../../domain/usecases/toggle_saved_post.dart';

// ── Infrastructure ─────────────────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main()');
});

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return DioClient(secureStorage: storage);
});

// ── DataSources ─────────────────────────────────────────────────────────────
final newsRemoteDataSourceProvider = Provider<NewsRemoteDataSource>((ref) {
  return NewsRemoteDataSourceImpl(ref.read(dioClientProvider));
});

final newsLocalDataSourceProvider = Provider<NewsLocalDataSource>((ref) {
  return NewsLocalDataSourceImpl(ref.read(sharedPreferencesProvider));
});

final contentRemoteDataSourceProvider = Provider<ContentRemoteDataSource>((ref) {
  return ContentRemoteDataSource(ref.read(dioClientProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    ref.read(dioClientProvider),
    ref.read(secureStorageProvider),
  );
});

// ── Repositories ─────────────────────────────────────────────────────────────
final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepositoryImpl(
    ref.read(newsRemoteDataSourceProvider),
    ref.read(newsLocalDataSourceProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.read(authRemoteDataSourceProvider),
    ref.read(secureStorageProvider),
  );
});

// ── UseCases ─────────────────────────────────────────────────────────────────
final getLatestNewsProvider = Provider(
  (ref) => GetLatestNews(ref.read(newsRepositoryProvider)),
);
final getBreakingNewsProvider = Provider(
  (ref) => GetBreakingNews(ref.read(newsRepositoryProvider)),
);
final getTrendingNewsProvider = Provider(
  (ref) => GetTrendingNews(ref.read(newsRepositoryProvider)),
);
final getCategoriesProvider = Provider(
  (ref) => GetCategories(ref.read(newsRepositoryProvider)),
);
final getNewsByCategoryProvider = Provider(
  (ref) => GetNewsByCategory(ref.read(newsRepositoryProvider)),
);
final getRelatedPostsProvider = Provider(
  (ref) => GetRelatedPosts(ref.read(newsRepositoryProvider)),
);
final searchNewsProvider = Provider(
  (ref) => SearchNews(ref.read(newsRepositoryProvider)),
);
final toggleSavedPostProvider = Provider(
  (ref) => ToggleSavedPost(ref.read(newsRepositoryProvider)),
);
final loginUserProvider = Provider(
  (ref) => LoginUser(ref.read(authRepositoryProvider)),
);
