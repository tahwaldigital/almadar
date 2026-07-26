import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// روابط التواصل الاجتماعي كما ضبطها المشرف في لوحة تحكم التطبيق على الموقع
/// (قسم Social links). تُقرأ من نقطة `config` وتُخزَّن مؤقتًا خلال الجلسة.
final socialLinksProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  try {
    final config = await ref.read(contentRemoteDataSourceProvider).getConfig();
    final social = config['social'];
    if (social is Map) {
      return social.map(
        (k, v) => MapEntry(k.toString(), (v ?? '').toString().trim()),
      );
    }
  } catch (_) {
    // تعذّر الوصول — نُخفي القسم بدل إظهار خطأ.
  }
  return const <String, String>{};
});
