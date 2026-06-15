import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/article_model.dart';
import '../../models/author_model.dart';
import '../../models/comment_model.dart';
import '../../models/page_model.dart';

/// Read/write access to the extra content endpoints (comments, videos,
/// authors, pages, most-viewed, config).
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

  // ── Comments ────────────────────────────────────────────────────────
  Future<List<CommentModel>> getComments(int postId, {int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiConstants.comments,
        queryParameters: {'post': postId, 'page': page, 'per_page': 20},
      );
      final list = (_unwrap(res.data) as List?) ?? const [];
      return list
          .map((j) => CommentModel.fromAlmadarJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  /// Returns a record of (comment, approved, message).
  Future<({CommentModel? comment, bool approved, String message})> postComment({
    required int postId,
    required String content,
    String authorName = '',
    String authorEmail = '',
    int parent = 0,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.comments,
        data: {
          'post': postId,
          'content': content,
          'author_name': authorName,
          'author_email': authorEmail,
          'parent': parent,
        },
      );
      final data = _unwrap(res.data) as Map<String, dynamic>;
      final c = data['comment'] as Map<String, dynamic>?;
      return (
        comment: c != null ? CommentModel.fromAlmadarJson(c) : null,
        approved: data['approved'] as bool? ?? false,
        message: data['message'] as String? ?? '',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
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
