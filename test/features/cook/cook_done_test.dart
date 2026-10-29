import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';

import 'fixtures.dart';

void main() {
  final byId = {for (final i in cookIngredientsFixture) i.id: i};

  test('chỉ đồ có trong tủ, bỏ gia vị cơ bản, lượng theo khẩu phần', () {
    final used = usedPantryItems(
      [(recipe: cookRecipeFixture, servings: 2)],
      {'egg', 'chili', 'oil'},
      byId,
    );
    expect(used, [
      const UsedItem(
        ingredientId: 'egg',
        name: 'Trứng gà',
        note: 'Đã dùng 4 quả',
        recipeIds: ['trung'],
      ),
      const UsedItem(
        ingredientId: 'chili',
        name: 'Ớt',
        note: 'Đã dùng 1 quả',
        recipeIds: ['trung'],
      ),
    ]);
  });

  test('nhiều món: cộng lượng, khác đơn vị thì ghép', () {
    const soup = Recipe(
      id: 'canh',
      name: 'Canh trứng',
      description: '',
      imageAsset: '',
      minutes: 10,
      servings: 2,
      tools: [],
      diets: [],
      meals: [],
      ingredients: [
        RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
        RecipeIngredient(id: 'scallion', amount: 20, unit: 'g'),
      ],
      steps: [RecipeStep(text: 'Nấu.')],
    );
    final used = usedPantryItems(
      [(recipe: cookRecipeFixture, servings: 1), (recipe: soup, servings: 2)],
      {'egg', 'scallion'},
      byId,
    );
    expect(used.map((u) => u.note), ['Đã dùng 4 quả', 'Đã dùng 1 nắm, 20 g']);
    expect(used.first.recipeIds, ['trung', 'canh']);
  });

  test('tủ trống thì không có gì', () {
    expect(usedPantryItems([(recipe: cookRecipeFixture, servings: 1)], const {}, byId), isEmpty);
  });
}
