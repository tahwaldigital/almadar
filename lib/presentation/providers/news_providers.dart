import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/article.dart';
import '../../domain/entities/category.dart';
import 'providers.dart';

// ── Breaking News ─────────────────────────────────────────────────────────────
final breakingNewsProvider = FutureProvider<List<Article>>((ref) async {
  final useCase = ref.read(getBreakingNewsProvider);
  final result = await useCase();
  return result.fold((f) => throw Exception(f.message), (articles) => articles);
});

// ── Latest News (Paginated) ────────────────────────────────────────────────────
class LatestNewsNotifier extends StateNotifier<AsyncValue<List<Article>>> {
  LatestNewsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  final Ref _ref;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitial() async {
    _page = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _fetch(reset: true);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    await _fetch(reset: false);
    _isLoadingMore = false;
  }

  Future<void> _fetch({required bool reset}) async {
    final useCase = _ref.read(getLatestNewsProvider);
    final result = await useCase(page: _page);
    result.fold(
      (failure) {
        if (reset) state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (articles) {
        if (articles.isEmpty || articles.length < 10) _hasMore = false;
        if (reset) {
          state = AsyncValue.data(articles);
        } else {
          final current = state.value ?? [];
          state = AsyncValue.data([...current, ...articles]);
        }
      },
    );
  }
}

final latestNewsProvider =
    StateNotifierProvider<LatestNewsNotifier, AsyncValue<List<Article>>>(
  (ref) => LatestNewsNotifier(ref),
);

// ── Trending News ─────────────────────────────────────────────────────────────
final trendingNewsProvider = FutureProvider<List<Article>>((ref) async {
  final useCase = ref.read(getTrendingNewsProvider);
  final result = await useCase();
  return result.fold((f) => throw Exception(f.message), (a) => a);
});

// ── Categories ────────────────────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final useCase = ref.read(getCategoriesProvider);
  final result = await useCase();
  return result.fold((f) => throw Exception(f.message), (c) => c);
});

// ── News By Category (Paginated) ──────────────────────────────────────────────
class CategoryNewsNotifier extends StateNotifier<AsyncValue<List<Article>>> {
  CategoryNewsNotifier(this._ref, this._categoryId)
      : super(const AsyncValue.loading()) {
    loadInitial();
  }

  final Ref _ref;
  final int _categoryId;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadInitial() async {
    _page = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _fetch(reset: true);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    await _fetch(reset: false);
    _isLoadingMore = false;
  }

  Future<void> _fetch({required bool reset}) async {
    final useCase = _ref.read(getNewsByCategoryProvider);
    final result = await useCase(_categoryId, page: _page);
    result.fold(
      (failure) {
        if (reset) state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (articles) {
        if (articles.isEmpty || articles.length < 10) _hasMore = false;
        if (reset) {
          state = AsyncValue.data(articles);
        } else {
          final current = state.value ?? [];
          state = AsyncValue.data([...current, ...articles]);
        }
      },
    );
  }
}

final categoryNewsProvider = StateNotifierProvider.family<
    CategoryNewsNotifier, AsyncValue<List<Article>>, int>(
  (ref, categoryId) => CategoryNewsNotifier(ref, categoryId),
);

// ── Single Article (full content by id) ────────────────────────────────────────
final articleByIdProvider =
    FutureProvider.family<Article, int>((ref, id) async {
  final repo = ref.read(newsRepositoryProvider);
  final result = await repo.getArticleById(id);
  return result.fold((f) => throw Exception(f.message), (a) => a);
});

// ── Related Posts ─────────────────────────────────────────────────────────────
final relatedPostsProvider =
    FutureProvider.family<List<Article>, ({int articleId, int categoryId})>(
  (ref, params) async {
    final useCase = ref.read(getRelatedPostsProvider);
    final result = await useCase(params.articleId, params.categoryId);
    return result.fold((f) => throw Exception(f.message), (a) => a);
  },
);

// ── Saved Articles ─────────────────────────────────────────────────────────────
class SavedArticlesNotifier extends StateNotifier<AsyncValue<List<Article>>> {
  SavedArticlesNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    final repo = _ref.read(newsRepositoryProvider);
    final result = await repo.getSavedArticles();
    result.fold(
      (f) => state = AsyncValue.error(f.message, StackTrace.current),
      (articles) => state = AsyncValue.data(articles),
    );
  }

  Future<bool> toggle(Article article) async {
    final useCase = _ref.read(toggleSavedPostProvider);
    final result = await useCase(article);
    await load();
    return result.fold((f) => false, (saved) => saved);
  }

  Future<void> clearAll() async {
    await _ref.read(newsLocalDataSourceProvider).clearSavedArticles();
    await load();
  }
}

final savedArticlesProvider =
    StateNotifierProvider<SavedArticlesNotifier, AsyncValue<List<Article>>>(
  (ref) => SavedArticlesNotifier(ref),
);

// ── Selected Category Tab ──────────────────────────────────────────────────────
final selectedCategoryProvider = StateProvider<int>((ref) => 0);
