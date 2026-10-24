import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _itemsKey = 'pantry.items';

/// Id nguyên liệu (`Ingredient.id`) người dùng đang có trong Tủ đồ.
///
/// Gia vị cơ bản (`isBasicSpice`) luôn coi là có, không cần nằm trong set này.
class PantryItemsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => Set.unmodifiable(ref.watch(localStoreProvider).readList(_itemsKey));

  Future<void> addToPantry(String ingredientId) => _save({...state, ingredientId});

  Future<void> removeFromPantry(String ingredientId) => _save({...state}..remove(ingredientId));

  Future<void> _save(Set<String> items) async {
    state = Set.unmodifiable(items);
    await ref.read(localStoreProvider).writeList(_itemsKey, items.toList());
  }
}

/// Đọc: `ref.watch(pantryItemsProvider)`. Thêm/bớt:
/// `ref.read(pantryItemsProvider.notifier).addToPantry('egg')`.
final pantryItemsProvider = NotifierProvider<PantryItemsController, Set<String>>(
  PantryItemsController.new,
);
