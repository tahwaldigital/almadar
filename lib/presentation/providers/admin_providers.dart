import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/admin_remote_datasource.dart';
import 'auth_providers.dart';
import 'providers.dart';

/// هل المستخدم الحالي مصرّح له بنشر الأخبار (لوحة التحرير)؟
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  return user?.canPublish ?? false;
});

/// يدير حالة إرسال منشور جديد من شاشة التحرير.
class PublishController extends StateNotifier<AsyncValue<PublishResult?>> {
  PublishController(this._ds) : super(const AsyncValue.data(null));

  final AdminRemoteDataSource _ds;

  Future<PublishResult?> publish({
    required String title,
    required String content,
    int? categoryId,
    String excerpt = '',
    String imageUrl = '',
    bool isBreaking = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _ds.createPost(
        title: title,
        content: content,
        categoryId: categoryId,
        excerpt: excerpt,
        imageUrl: imageUrl,
        isBreaking: isBreaking,
      );
      state = AsyncValue.data(res);
      return res;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final publishControllerProvider = StateNotifierProvider.autoDispose<
    PublishController, AsyncValue<PublishResult?>>((ref) {
  return PublishController(ref.read(adminRemoteDataSourceProvider));
});
