import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_items.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';

const _doneKey = 'plan.shoppingDone';

/// Dòng đã tick "đã mua" ở màn Đi chợ, theo `ShoppingRow.id`.
class ShoppingDoneController extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      Set.unmodifiable(ref.watch(localStoreProvider).readList(_doneKey).whereType<String>());

  Future<void> toggle(String id) async {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    await _save(next);
  }

  Future<void> clear() => _save(const {});

  Future<void> _save(Set<String> ids) async {
    state = Set.unmodifiable(ids);
    await ref.read(localStoreProvider).writeList(_doneKey, ids.toList());
  }
}

final shoppingDoneProvider = NotifierProvider<ShoppingDoneController, Set<String>>(
  ShoppingDoneController.new,
);

/// Danh sách đi chợ đã gộp đồ tự thêm và trừ Tủ đồ ([buildShoppingSheet]).
final shoppingSheetProvider = Provider<AsyncValue<ShoppingSheet>>((ref) {
  final lines = ref.watch(shoppingListProvider);
  final ingredients = ref.watch(ingredientsProvider);
  final recipes = ref.watch(recipesProvider);
  final items = ref.watch(shoppingItemsProvider);
  final pantry = ref.watch(pantryItemsProvider);
  return switch ((lines, ingredients, recipes)) {
    (AsyncError(:final error, :final stackTrace), _, _) ||
    (_, AsyncError(:final error, :final stackTrace), _) ||
    (_, _, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
    (
      AsyncData(value: final lines),
      AsyncData(value: final ingredients),
      AsyncData(
        value: final recipes,
      ),
    ) =>
      AsyncData(
        buildShoppingSheet(
          lines: lines,
          items: [for (final i in items) (ingredientId: i.ingredientId, name: i.name)],
          ingredientsById: {for (final i in ingredients) i.id: i},
          recipesById: {for (final r in recipes) r.id: r},
          pantry: pantry,
        ),
      ),
    _ => const AsyncLoading(),
  };
});

/// Số trên badge nút Đi chợ: số dòng chưa tick. Đang tải dữ liệu đóng gói thì tạm đếm đồ tự thêm.
final shoppingCountProvider = Provider<int>((ref) {
  final sheet = ref.watch(shoppingSheetProvider).value;
  if (sheet == null) return ref.watch(shoppingItemsProvider).length;
  final done = ref.watch(shoppingDoneProvider);
  return sheet.groups.fold(0, (sum, g) => sum + g.rows.where((r) => !done.contains(r.id)).length);
});
