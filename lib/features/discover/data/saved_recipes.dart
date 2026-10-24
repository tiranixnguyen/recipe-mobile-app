import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _savedKey = 'discover.saved';

/// Id món đã lưu, theo thứ tự lưu (cũ trước, mới sau).
class SavedRecipesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => Set.unmodifiable(ref.watch(localStoreProvider).readList(_savedKey));

  /// Lưu nếu chưa lưu, bỏ lưu nếu đã lưu.
  Future<void> toggle(String recipeId) async {
    final next = {...state};
    if (!next.remove(recipeId)) next.add(recipeId);
    state = Set.unmodifiable(next);
    await ref.read(localStoreProvider).writeList(_savedKey, next.toList());
  }
}

/// Đọc: `ref.watch(savedIdsProvider).contains(id)`. Đổi:
/// `ref.read(savedIdsProvider.notifier).toggle(id)`; trên giao diện dùng `SaveButton`.
final savedIdsProvider = NotifierProvider<SavedRecipesController, Set<String>>(
  SavedRecipesController.new,
);
