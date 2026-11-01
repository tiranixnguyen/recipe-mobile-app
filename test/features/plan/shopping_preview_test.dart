import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_items.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_sheet.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';

Recipe _recipe(String id, String name) => Recipe(
  id: id,
  name: name,
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: const [],
  diets: const [],
  meals: const [],
  ingredients: const [],
  steps: const [],
);

const _ingredients = [
  Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein),
  Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
];

ProviderContainer _container({
  List<ShoppingLine> lines = const [
    ShoppingLine(ingredientId: 'egg', unit: 'quả', amount: 2, recipeIds: ['fried']),
  ],
}) {
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      ingredientsProvider.overrideWithValue(const AsyncData(_ingredients)),
      recipesProvider.overrideWithValue(AsyncData([_recipe('fried', 'Trứng chiên')])),
      shoppingListProvider.overrideWith((ref) => AsyncData(lines)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('tên theo thứ tự trên màn Đi chợ, không kèm lượng', () async {
    final c = _container();
    expect(c.read(shoppingPreviewProvider), ['Trứng gà']);
  });

  test('bỏ dòng đã tick', () async {
    final c = _container();
    final id = c.read(shoppingSheetProvider).value!.groups.single.rows.single.id;
    await c.read(shoppingDoneProvider.notifier).toggle(id);
    expect(c.read(shoppingPreviewProvider), isEmpty);
  });

  test('đồ tự gõ lấy tên đã gõ, gộp theo thứ tự nhóm', () async {
    final c = _container(lines: const []);
    await c.read(shoppingItemsProvider.notifier).addIngredient('scallion');
    await c.read(shoppingItemsProvider.notifier).addCustom('Giấy ăn');

    expect(c.read(shoppingPreviewProvider), ['Hành lá', 'Giấy ăn']);
  });

  test('đang tải danh sách đóng gói thì trả rỗng', () async {
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith((ref) => Completer<List<Ingredient>>().future),
        recipesProvider.overrideWithValue(const AsyncData([])),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(shoppingPreviewProvider), isEmpty);
  });
}
