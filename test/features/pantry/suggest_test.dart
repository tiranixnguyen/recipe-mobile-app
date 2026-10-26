import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

Recipe _recipe(String id, List<Meal> meals) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: 'assets/images/recipes/$id.jpg',
  minutes: 10,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: meals,
  ingredients: const [RecipeIngredient(id: 'egg', amount: 1, unit: 'quả')],
  steps: const [RecipeStep(text: 'Nấu.')],
);

void main() {
  final recipes = [
    _recipe('sang', [Meal.breakfast]),
    _recipe('moi-bua', []),
    _recipe('toi', [Meal.dinner]),
    _recipe('trua-toi', [Meal.lunch, Meal.dinner]),
  ];

  List<String> ids(List<Recipe> list) => [for (final r in list) r.id];

  test('lọc theo bữa, meals rỗng là mọi bữa', () {
    expect(ids(suggest(recipes, meal: Meal.dinner, count: 10)), ['moi-bua', 'toi', 'trua-toi']);
    expect(ids(suggest(recipes, meal: Meal.breakfast, count: 10)), ['sang', 'moi-bua']);
  });

  test('lấy tối đa count món', () {
    expect(ids(suggest(recipes, meal: Meal.dinner, count: 2)), ['moi-bua', 'toi']);
  });

  test('bỏ món đã chê', () {
    expect(
      ids(suggest(recipes, meal: Meal.dinner, count: 10, disliked: {'toi'})),
      ['moi-bua', 'trua-toi'],
    );
  });

  test('món vừa bị chê xuống cuối, vẫn giữ thứ tự', () {
    expect(
      ids(suggest(recipes, meal: Meal.dinner, count: 10, demoted: {'moi-bua', 'toi'})),
      ['trua-toi', 'moi-bua', 'toi'],
    );
    expect(ids(suggest(recipes, meal: Meal.dinner, count: 1, demoted: {'moi-bua'})), ['toi']);
  });
}
