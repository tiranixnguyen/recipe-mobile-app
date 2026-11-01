import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_items.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_sheet.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';
import 'package:recipe_mobile_app/features/plan/presentation/shopping/shopping_view_model.dart';

import '../../core/fake_analytics.dart';

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
  Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
  Ingredient(id: 'rice', name: 'Gạo', group: IngredientGroup.starch),
];

late FakeAnalytics _analytics;

ProviderContainer _container({
  List<ShoppingLine> lines = const [
    ShoppingLine(ingredientId: 'egg', unit: 'quả', amount: 2, recipeIds: ['fried']),
  ],
}) {
  _analytics = FakeAnalytics();
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
      analyticsProvider.overrideWithValue(_analytics),
      ingredientsProvider.overrideWithValue(const AsyncData(_ingredients)),
      recipesProvider.overrideWithValue(AsyncData([_recipe('fried', 'Trứng chiên')])),
      shoppingListProvider.overrideWith((ref) => AsyncData(lines)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(shoppingViewModelProvider, (_, _) {});
  return container;
}

ShoppingState _state(ProviderContainer c) => c.read(shoppingViewModelProvider).requireValue;

void main() {
  test('tick đã mua lưu vào LocalStore và sống qua lần dựng lại', () async {
    final c = _container();
    final id = _state(c).rows.single.id;
    await c.read(shoppingViewModelProvider.notifier).toggle(id);
    expect(_state(c).done, {id});
    expect(c.read(localStoreProvider).readList('plan.shoppingDone'), [id]);

    await c.read(shoppingViewModelProvider.notifier).toggle(id);
    expect(_state(c).done, isEmpty);
  });

  test('badge là số dòng chưa tick, tính cả dòng từ thực đơn', () async {
    final c = _container();
    await c.read(shoppingItemsProvider.notifier).addIngredient('rice');
    expect(c.read(shoppingCountProvider), 2);
    await c.read(shoppingViewModelProvider.notifier).toggle(_state(c).rows.first.id);
    expect(c.read(shoppingCountProvider), 1);
  });

  test('đồ tự thêm trùng dòng của thực đơn thì gộp, không hiện hai dòng', () async {
    final c = _container();
    await c.read(shoppingItemsProvider.notifier).addIngredient('egg');
    expect(_state(c).rows.map((r) => r.name), ['Trứng gà · 2 quả']);
  });

  test('cất vào tủ: thứ đã tick vào Tủ đồ, đồ tự thêm ra khỏi đi chợ, ghi shopping_done', () async {
    final c = _container();
    await c.read(shoppingItemsProvider.notifier).addIngredient('rice');
    await c.read(shoppingItemsProvider.notifier).addCustom('Giấy ăn');
    final notifier = c.read(shoppingViewModelProvider.notifier);
    for (final r in _state(c).rows.where((r) => r.name != 'Trứng gà · 2 quả')) {
      await notifier.toggle(r.id);
    }

    expect(await notifier.complete(), 2);
    expect(c.read(pantryItemsProvider), {'rice'});
    expect(c.read(shoppingItemsProvider), isEmpty);
    expect(c.read(shoppingDoneProvider), isEmpty);
    expect(_state(c).rows.map((r) => r.name), ['Trứng gà · 2 quả']);
    expect(_analytics.events.last, 'shopping_done');
    expect(_analytics.params.last, {'items': 2});
  });

  test('chưa tick gì thì cất vào tủ không làm gì', () async {
    final c = _container();
    expect(await c.read(shoppingViewModelProvider.notifier).complete(), 0);
    expect(_analytics.events, isEmpty);
  });

  test('đã có trong Tủ đồ thì bỏ khỏi danh sách và ghi vào inPantry', () async {
    final c = _container();
    await c.read(pantryItemsProvider.notifier).addToPantry('egg');
    expect(_state(c).isEmpty, isTrue);
    expect(_state(c).inPantry, ['trứng gà']);
  });
}
