import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';

/// نتيجة إنشاء منشور جديد من لوحة التحرير.
class PublishResult {
  final int id;
  final String link;
  final bool breakingSent;

  const PublishResult({
    required this.id,
    required this.link,
    required this.breakingSent,
  });
}

/// مصدر بيانات لوحة التحرير: إنشاء منشورات ووردبريس من داخل التطبيق.
///
/// يعتمد على رأس المصادقة (Bearer) الذي يحقنه [DioClient] تلقائيًا، فلا
/// يُرسَل أي توكن يدويًا. يجب أن يتحقق الخادم من صلاحية المستخدم للنشر.
class AdminRemoteDataSource {
  final DioClient _dio;

  AdminRemoteDataSource(this._dio);

  Map<String, dynamic> _data(dynamic body) {
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return (body as Map<String, dynamic>?) ?? const {};
  }

  /// ينشئ منشورًا. عند [isBreaking] يعامله الخادم كخبر عاجل ويُرسل الإشعار.
  Future<PublishResult> createPost({
    required String title,
    required String content,
    int? categoryId,
    String excerpt = '',
    String imageUrl = '',
    bool isBreaking = false,
    String status = 'publish',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminCreatePost,
        data: {
          'title': title,
          'content': content,
          if (excerpt.isNotEmpty) 'excerpt': excerpt,
          if (categoryId != null) 'category_id': categoryId,
          if (imageUrl.isNotEmpty) 'image_url': imageUrl,
          'is_breaking': isBreaking,
          'status': status,
        },
      );
      final d = _data(response.data);
      return PublishResult(
        id: d['id'] as int? ?? 0,
        link: d['link'] as String? ?? '',
        // لا نفترض أن الإشعار أُرسل؛ الخادم وحده يؤكّد ذلك.
        breakingSent: d['breaking_sent'] == true,
      );
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'تعذّر نشر الخبر: ${e.toString()}');
    }
  }
}
