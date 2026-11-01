import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_items.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';
import 'package:recipe_mobile_app/features/plan/presentation/shopping/shopping_view_model.dart';

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

Ingredient _ingredient(String id, String name, IngredientGroup group, {bool basic = false}) =>
    Ingredient(
      id: id,
      name: name,
      group: group,
      isBasicSpice: basic,
    );

ProviderContainer _container({
  required InMemoryLocalStore store,
  required List<Ingredient> ingredients,
  required List<Recipe> recipes,
  required List<ShoppingLine> lines,
}) {
  return ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => store),
      ingredientsProvider.overrideWithValue(AsyncData(ingredients)),
      recipesProvider.overrideWithValue(AsyncData(recipes)),
      shoppingListProvider.overrideWith((ref) => AsyncData(lines)),
    ],
  );
}

ShoppingState _state(ProviderContainer container) =>
    container.read(shoppingViewModelProvider).requireValue;

void main() {
  test('toggle nguyên liệu đã mua và lưu trạng thái vào LocalStore', () async {
    final store = InMemoryLocalStore();
    final container = _container(
      store: store,
      ingredients: [_ingredient('egg', 'Trứng', IngredientGroup.protein)],
      recipes: [_recipe('fried-egg', 'Trứng chiên')],
      lines: const [
        ShoppingLine(ingredientId: 'egg', unit: 'quả', amount: 2, recipeIds: ['fried-egg']),
      ],
    );
    addTearDown(container.dispose);

    final id = _state(container).groups.single.items.single.id;
    await container.read(shoppingViewModelProvider.notifier).toggle(id);

    expect(_state(container).doneIds, {id});
    expect(store.readList('plan.shoppingDone'), [id]);
  });

  test('complete thêm nguyên liệu đã mua vào Tủ đồ', () async {
    final store = InMemoryLocalStore();
    final container = _container(
      store: store,
      ingredients: [_ingredient('egg', 'Trứng', IngredientGroup.protein)],
      recipes: [_recipe('fried-egg', 'Trứng chiên')],
      lines: const [
        ShoppingLine(ingredientId: 'egg', unit: 'quả', amount: 1, recipeIds: ['fried-egg']),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(shoppingViewModelProvider.notifier);
    await notifier.toggle(_state(container).groups.single.items.single.id);
    await notifier.complete();

    expect(container.read(pantryItemsProvider), {'egg'});
  });

  test('complete xoá món tự thêm và dọn danh sách đã tích', () async {
    final store = InMemoryLocalStore();
    final container = _container(
      store: store,
      ingredients: const [],
      recipes: const [],
      lines: const [],
    );
    addTearDown(container.dispose);

    await container.read(shoppingItemsProvider.notifier).addCustom('Nước mắm');
    final notifier = container.read(shoppingViewModelProvider.notifier);
    final id = _state(container).groups.single.items.single.id;
    await notifier.toggle(id);
    await notifier.complete();

    expect(container.read(shoppingItemsProvider), isEmpty);
    expect(store.readList('plan.shoppingDone'), isEmpty);
  });

  test('lọc gia vị cơ bản và nguyên liệu đã có trong tủ', () async {
    final store = InMemoryLocalStore();
    final container = _container(
      store: store,
      ingredients: [
        _ingredient('egg', 'Trứng', IngredientGroup.protein),
        _ingredient('salt', 'Muối', IngredientGroup.spice, basic: true),
        _ingredient('rice', 'Gạo', IngredientGroup.starch),
      ],
      recipes: [_recipe('meal', 'Bữa cơm')],
      lines: const [
        ShoppingLine(ingredientId: 'egg', unit: 'quả', amount: 1, recipeIds: ['meal']),
        ShoppingLine(ingredientId: 'salt', unit: 'nhúm', amount: 1, recipeIds: ['meal']),
        ShoppingLine(ingredientId: 'rice', unit: 'bát', amount: 1, recipeIds: ['meal']),
      ],
    );
    addTearDown(container.dispose);
    await container.read(pantryItemsProvider.notifier).addToPantry('rice');

    final items = [for (final group in _state(container).groups) ...group.items];
    expect(items.map((item) => item.ingredientId), ['egg']);
  });

  test('subtitle dùng tên món từ Recipe API', () {
    final store = InMemoryLocalStore();
    final container = _container(
      store: store,
      ingredients: [_ingredient('egg', 'Trứng', IngredientGroup.protein)],
      recipes: [_recipe('recipe-id', 'Tên món thật')],
      lines: const [
        ShoppingLine(ingredientId: 'egg', unit: 'quả', amount: 1, recipeIds: ['recipe-id']),
      ],
    );
    addTearDown(container.dispose);

    expect(_state(container).groups.single.items.single.subtitle, 'Tên món thật');
  });
}
