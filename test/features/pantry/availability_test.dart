import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

void main() {
  const ingredients = {
    'egg': Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
    'scallion': Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
    'tomato': Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
    'oil': Ingredient(id: 'oil', name: 'Dầu ăn', group: IngredientGroup.spice, isBasicSpice: true),
  };

  const recipe = Recipe(
    id: 'trung-chien',
    name: 'Trứng chiên',
    description: '',
    imageAsset: 'assets/images/recipes/trung-chien.jpg',
    minutes: 10,
    servings: 1,
    tools: [Tool.stove],
    diets: [],
    meals: [],
    ingredients: [
      RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
      RecipeIngredient(id: 'scallion', amount: 1, unit: 'nhánh'),
      RecipeIngredient(id: 'tomato', amount: 1, unit: 'quả', optional: true),
      RecipeIngredient(id: 'oil', amount: 1, unit: 'muỗng canh'),
    ],
    steps: [RecipeStep(text: 'Chiên trứng.')],
  );

  test('đủ đồ khi có mọi nguyên liệu bắt buộc', () {
    final result = availabilityFor(recipe, {'egg', 'scallion'}, ingredients);
    expect(result.isReady, isTrue);
    expect(result.missing, isEmpty);
  });

  test('thiếu: tên viết thường theo thứ tự công thức', () {
    final result = availabilityFor(recipe, {}, ingredients);
    expect(result.isReady, isFalse);
    expect(result.missing, ['trứng', 'hành lá']);
  });

  test('bỏ qua nguyên liệu tuỳ chọn và gia vị cơ bản', () {
    final result = availabilityFor(recipe, {'egg'}, ingredients);
    expect(result, const Availability(missing: ['hành lá']));
  });

  test('id không có trong danh mục thì hiện bằng id', () {
    final result = availabilityFor(recipe, {'scallion'}, const {});
    expect(result.missing, ['egg', 'oil']);
  });
}
