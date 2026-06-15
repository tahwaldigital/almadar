import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/article.dart';
import 'providers.dart';

// ── Search Query State ─────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Search Results ─────────────────────────────────────────────────────────────
class SearchNotifier extends StateNotifier<AsyncValue<List<Article>>> {
  SearchNotifier(this._ref) : super(const AsyncValue.data([]));

  final Ref _ref;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _lastQuery = '';

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _lastQuery = query;
    _page = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _fetch(reset: true);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _lastQuery.isEmpty) return;
    _isLoadingMore = true;
    _page++;
    await _fetch(reset: false);
    _isLoadingMore = false;
  }

  Future<void> _fetch({required bool reset}) async {
    final useCase = _ref.read(searchNewsProvider);
    final result = await useCase(_lastQuery, page: _page);
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

  void clear() {
    _lastQuery = '';
    state = const AsyncValue.data([]);
  }
}

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<Article>>>(
  (ref) => SearchNotifier(ref),
);

// ── Search History ─────────────────────────────────────────────────────────────
final searchHistoryProvider = FutureProvider<List<String>>((ref) async {
  final local = ref.read(newsLocalDataSourceProvider);
  return local.getSearchHistory();
});
