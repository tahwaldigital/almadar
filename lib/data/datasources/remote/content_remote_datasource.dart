import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/article_model.dart';
import '../../models/author_model.dart';
import '../../models/page_model.dart';

/// Read access to the extra content endpoints (videos, authors, pages,
/// most-viewed, config).
class ContentRemoteDataSource {
  final DioClient _dio;
  ContentRemoteDataSource(this._dio);

  dynamic _unwrap(dynamic data) =>
      (data is Map<String, dynamic>) ? data['data'] : data;

  List<ArticleModel> _articles(dynamic data) {
    final list = (data as List?) ?? const [];
    return list
        .map((j) => ArticleModel.fromAlmadarJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Videos ──────────────────────────────────────────────────────────
  Future<List<ArticleModel>> getVideos({int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiConstants.videos,
        queryParameters: {'page': page, 'per_page': 10},
      );
      return _articles(_unwrap(res.data));
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Most viewed ─────────────────────────────────────────────────────
  Future<List<ArticleModel>> getMostViewed({int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiConstants.mostViewed,
        queryParameters: {'page': page, 'per_page': 10},
      );
      return _articles(_unwrap(res.data));
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Authors ─────────────────────────────────────────────────────────
  Future<AuthorModel> getAuthor(int id) async {
    try {
      final res = await _dio.get('${ApiConstants.authors}/$id');
      return AuthorModel.fromAlmadarJson(_unwrap(res.data) as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<List<ArticleModel>> getAuthorPosts(int id, {int page = 1}) async {
    try {
      final res = await _dio.get(
        '${ApiConstants.authors}/$id/posts',
        queryParameters: {'page': page, 'per_page': 10},
      );
      return _articles(_unwrap(res.data));
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Pages ───────────────────────────────────────────────────────────
  Future<PageModel> getPage(int id) async {
    try {
      final res = await _dio.get('${ApiConstants.pages}/$id');
      return PageModel.fromAlmadarJson(_unwrap(res.data) as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Config ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getConfig() async {
    try {
      final res = await _dio.get(ApiConstants.config);
      final data = _unwrap(res.data);
      return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
