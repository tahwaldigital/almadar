import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/article_model.dart';
import '../../models/category_model.dart';

abstract class NewsRemoteDataSource {
  Future<List<ArticleModel>> getLatestNews({int page = 1, int perPage = 10});
  Future<List<ArticleModel>> getBreakingNews();
  Future<List<ArticleModel>> getTrendingNews({int page = 1});
  Future<List<ArticleModel>> getMostViewedNews();
  Future<List<ArticleModel>> getNewsByCategory(int categoryId, {int page = 1, int perPage = 10});
  Future<List<ArticleModel>> getRelatedPosts(int articleId, int categoryId);
  Future<List<ArticleModel>> searchNews(String query, {int page = 1});
  Future<ArticleModel> getArticleById(int id);
  Future<List<CategoryModel>> getCategories();
  Future<void> incrementView(int articleId);
}

class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  final DioClient _dio;

  NewsRemoteDataSourceImpl(this._dio);

  /// Unwraps the standard envelope { success, data, meta } and returns `data`.
  dynamic _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['data'];
    }
    return responseData;
  }

  List<ArticleModel> _mapArticles(dynamic data, {bool isTrending = false}) {
    final list = (data as List?) ?? const [];
    return list
        .map((json) => ArticleModel.fromAlmadarJson(
              json as Map<String, dynamic>,
              isTrending: isTrending,
            ))
        .toList();
  }

  @override
  Future<List<ArticleModel>> getLatestNews({int page = 1, int perPage = 10}) async {
    try {
      final response = await _dio.get(
        ApiConstants.posts,
        queryParameters: {'page': page, 'per_page': perPage, 'orderby': 'date', 'order': 'desc'},
      );
      return _mapArticles(_unwrap(response.data));
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ArticleModel>> getBreakingNews() async {
    try {
      final response = await _dio.get(ApiConstants.breakingNews);
      final data = _unwrap(response.data);
      // breaking-news returns { banner, items }
      final items = (data is Map<String, dynamic>) ? data['items'] : data;
      return _mapArticles(items);
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ArticleModel>> getTrendingNews({int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstants.trending,
        queryParameters: {'page': page, 'per_page': 10},
      );
      return _mapArticles(_unwrap(response.data), isTrending: true);
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ArticleModel>> getMostViewedNews() async {
    try {
      final response = await _dio.get(
        ApiConstants.mostViewed,
        queryParameters: {'per_page': 10},
      );
      return _mapArticles(_unwrap(response.data));
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ArticleModel>> getNewsByCategory(int categoryId, {int page = 1, int perPage = 10}) async {
    try {
      final response = await _dio.get(
        ApiConstants.posts,
        queryParameters: {'category': categoryId, 'page': page, 'per_page': perPage, 'orderby': 'date', 'order': 'desc'},
      );
      return _mapArticles(_unwrap(response.data));
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ArticleModel>> getRelatedPosts(int articleId, int categoryId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.posts}/$articleId/related',
        queryParameters: {'per_page': 6},
      );
      return _mapArticles(_unwrap(response.data));
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ArticleModel>> searchNews(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiConstants.search,
        queryParameters: {'search': query, 'page': page, 'per_page': 10},
      );
      return _mapArticles(_unwrap(response.data));
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ArticleModel> getArticleById(int id) async {
    try {
      final response = await _dio.get('${ApiConstants.posts}/$id');
      return ArticleModel.fromAlmadarJson(_unwrap(response.data) as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final list = (_unwrap(response.data) as List?) ?? const [];
      return list
          .map((json) => CategoryModel.fromAlmadarJson(json as Map<String, dynamic>))
          .toList();
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> incrementView(int articleId) async {
    try {
      await _dio.post('${ApiConstants.posts}/$articleId/view');
    } catch (_) {
      // View counting is best-effort; never block the UI.
    }
  }
}
