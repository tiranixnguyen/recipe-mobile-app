import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _savedKey = 'discover.saved';

/// Id món đã lưu, theo thứ tự lưu (cũ trước, mới sau).
class SavedRecipesController extends Notifier<Set<String>> {
  Future<void> _pending = Future.value();

  @override
  Set<String> build() => Set.unmodifiable(ref.watch(localStoreProvider).readList(_savedKey));

  /// Lưu nếu chưa lưu, bỏ lưu nếu đã lưu. Các lần bấm liên tiếp phải chờ ghi trước đó.
  Future<void> toggle(String recipeId) {
    final operation = _pending.then((_) async {
      final next = {...state};
      if (!next.remove(recipeId)) next.add(recipeId);
      await ref.read(localStoreProvider).writeList(_savedKey, next.toList());
      state = Set.unmodifiable(next);
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}

/// Đọc: `ref.watch(savedIdsProvider).contains(id)`. Đổi:
/// `ref.read(savedIdsProvider.notifier).toggle(id)`; trên giao diện dùng `SaveButton`.
final savedIdsProvider = NotifierProvider<SavedRecipesController, Set<String>>(
  SavedRecipesController.new,
);
