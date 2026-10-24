import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/domain/matches.dart';

const _ingredients = {
  'egg': Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
  'tomato': Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
  'scallion': Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  'noodle': Ingredient(id: 'noodle', name: 'Mì gói', group: IngredientGroup.starch),
  'salt': Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
};

Recipe _recipe(String id, List<String> needs) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: [for (final n in needs) RecipeIngredient(id: n, amount: 1, unit: 'g')],
  steps: const [],
);

void main() {
  final recipes = [
    _recipe('two-missing', ['egg', 'tomato', 'scallion']),
    _recipe('ready', ['egg', 'salt']),
    _recipe('one-missing', ['egg', 'noodle']),
    _recipe('three-missing', ['tomato', 'scallion', 'noodle']),
    _recipe('one-missing-later', ['egg', 'scallion']),
  ];

  test('chia đủ đồ / thiếu 1–2 thứ, bỏ món thiếu nhiều hơn', () {
    final matches = matchPantry(recipes, {'egg'}, _ingredients);

    expect(matches.ready.map((r) => r.id), ['ready']);
    expect(matches.near.map((m) => m.recipe.id), [
      'one-missing',
      'one-missing-later',
      'two-missing',
    ]);
    expect(matches.near.first.availability.missing, ['mì gói']);
  });

  test('tủ trống: gia vị cơ bản không tính là thiếu', () {
    final matches = matchPantry(recipes, const {}, _ingredients);

    expect(matches.ready, isEmpty);
    expect(matches.near.map((m) => m.recipe.id), ['ready', 'one-missing', 'one-missing-later']);
    expect(matches.near.first.availability.missing, ['trứng']);
  });

  test('maxMissing đổi được ngưỡng', () {
    final matches = matchPantry(recipes, {'egg'}, _ingredients, maxMissing: 1);
    expect(matches.near.map((m) => m.recipe.id), ['one-missing', 'one-missing-later']);
  });
}
