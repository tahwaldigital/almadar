import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

const _readKey = 'read_article_ids';
const _maxTracked = 600;

/// يتتبّع معرّفات المقالات التي فتحها المستخدم (لعرض مؤشّر «غير مقروء»).
class ReadArticlesNotifier extends StateNotifier<Set<int>> {
  ReadArticlesNotifier(this._ref) : super(_load(_ref));

  final Ref _ref;

  static Set<int> _load(Ref ref) {
    final prefs = ref.read(sharedPreferencesProvider);
    final list = prefs.getStringList(_readKey) ?? const [];
    return list.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> markRead(int id) async {
    if (id <= 0 || state.contains(id)) return;
    final next = {...state, id};
    state = next;
    final prefs = _ref.read(sharedPreferencesProvider);
    var ids = next.toList();
    if (ids.length > _maxTracked) {
      ids = ids.sublist(ids.length - _maxTracked);
    }
    await prefs.setStringList(_readKey, ids.map((e) => e.toString()).toList());
  }

  bool isRead(int id) => state.contains(id);
}

final readArticlesProvider =
    StateNotifierProvider<ReadArticlesNotifier, Set<int>>(
  (ref) => ReadArticlesNotifier(ref),
);
