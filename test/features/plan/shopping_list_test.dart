import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';

Recipe _recipe(String id, {int servings = 1, required List<RecipeIngredient> ingredients}) =>
    Recipe(
      id: id,
      name: id,
      description: '',
      imageAsset: '',
      minutes: 10,
      servings: servings,
      tools: const [],
      diets: const [],
      meals: const [],
      ingredients: ingredients,
      steps: const [],
    );

final _trung = _recipe(
  'trung-chien',
  ingredients: const [
    RecipeIngredient(id: 'trung', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'hanh-la', amount: 1, unit: 'nhánh'),
  ],
);

/// Công thức cho 2 người.
final _canh = _recipe(
  'canh-ca-chua',
  servings: 2,
  ingredients: const [
    RecipeIngredient(id: 'ca-chua', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'trung', amount: 1, unit: 'quả'),
    RecipeIngredient(id: 'hanh-la', amount: 10, unit: 'g'),
  ],
);

final _byId = {
  for (final r in [_trung, _canh]) r.id: r,
};

void main() {
  group('gatherShopping', () {
    test('nhân theo khẩu phần, cộng dồn cùng nguyên liệu và đơn vị, giữ thứ tự', () {
      final lines = gatherShopping([
        (recipeId: 'trung-chien', servings: 2),
        (recipeId: 'canh-ca-chua', servings: 1),
      ], _byId);

      expect(lines, const [
        ShoppingLine(
          ingredientId: 'trung',
          unit: 'quả',
          amount: 4.5,
          recipeIds: ['trung-chien', 'canh-ca-chua'],
        ),
        ShoppingLine(ingredientId: 'hanh-la', unit: 'nhánh', amount: 2, recipeIds: ['trung-chien']),
        ShoppingLine(ingredientId: 'ca-chua', unit: 'quả', amount: 1, recipeIds: ['canh-ca-chua']),
        // Khác đơn vị thì tách dòng.
        ShoppingLine(ingredientId: 'hanh-la', unit: 'g', amount: 5, recipeIds: ['canh-ca-chua']),
      ]);
    });

    test('cùng món hai lần thì cộng lượng, không lặp tên món', () {
      final lines = gatherShopping([
        (recipeId: 'trung-chien', servings: 1),
        (recipeId: 'trung-chien', servings: 3),
      ], _byId);
      expect(lines.first.amount, 8);
      expect(lines.first.recipeIds, ['trung-chien']);
    });

    test('món id lạ bị bỏ qua; không có món thì rỗng', () {
      expect(gatherShopping([(recipeId: 'mon-cu', servings: 2)], _byId), isEmpty);
      expect(gatherShopping(const [], _byId), isEmpty);
    });
  });

  test('shoppingListProvider: món trong thực đơn tuần này cộng món thêm đi chợ', () async {
    final container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        // Thứ Ba 20/10/2026.
        nowProvider.overrideWithValue(DateTime(2026, 10, 20, 9)),
        recipesProvider.overrideWith((ref) async => [_trung, _canh]),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(shoppingListProvider, (_, _) {});
    await container.read(recipesProvider.future);

    final plan = container.read(plannedMealsProvider.notifier);
    await plan.addToPlan('trung-chien', DateTime(2026, 10, 21), Meal.dinner, servings: 2);
    // Tuần sau: không tính.
    await plan.addToPlan('trung-chien', DateTime(2026, 10, 26), Meal.dinner, servings: 5);
    await container.read(shoppingProvider.notifier).addToShopping('canh-ca-chua', 2);

    final lines = sub.read().requireValue;
    expect(lines.map((l) => (l.ingredientId, l.unit, l.amount)), [
      ('trung', 'quả', 5),
      ('hanh-la', 'nhánh', 2),
      ('ca-chua', 'quả', 2),
      ('hanh-la', 'g', 10),
    ]);
  });
}
