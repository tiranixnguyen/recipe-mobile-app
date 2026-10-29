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

  test('lọc theo bữa, meals rỗng là mọi bữa nhưng xếp sau bữa rõ ràng', () {
    expect(ids(suggest(recipes, meal: Meal.dinner, count: 10)), ['toi', 'trua-toi', 'moi-bua']);
    expect(ids(suggest(recipes, meal: Meal.breakfast, count: 10)), ['sang', 'moi-bua']);
  });

  test('lấy tối đa count món', () {
    expect(ids(suggest(recipes, meal: Meal.dinner, count: 2)), ['toi', 'trua-toi']);
  });

  test('món đã chê không xuất hiện, kể cả đã lưu; không fallback nếu hết món', () {
    expect(
      ids(suggest(recipes, meal: Meal.dinner, count: 10, disliked: {'toi'})),
      ['trua-toi', 'moi-bua'],
    );
    expect(
      suggest([recipes[2]], meal: Meal.dinner, count: 3, saved: {'toi'}, disliked: {'toi'}),
      isEmpty,
    );
  });

  test('món bị chê xuống sau món không bị chê khi cùng mức thiếu', () {
    expect(
      ids(suggest(recipes, meal: Meal.dinner, count: 10, demoted: {'moi-bua', 'toi'})),
      ['trua-toi', 'toi', 'moi-bua'],
    );
  });

  test('lọc đúng dụng cụ và mọi chế độ ăn đã chọn; hồ sơ trống không lọc', () {
    final base = _recipe('base', [Meal.dinner]);
    final vegetarian = Recipe(
      id: 'chay',
      name: 'Chay',
      description: '',
      imageAsset: '',
      minutes: 15,
      servings: 1,
      tools: const [Tool.kettle],
      diets: const [Diet.veg],
      meals: const [Meal.dinner],
      ingredients: const [],
      steps: const [],
    );
    expect(
      ids(
        suggest(
          [base, vegetarian],
          meal: Meal.dinner,
          count: 9,
          tools: {Tool.kettle},
          diets: {Diet.veg},
        ),
      ),
      ['chay'],
    );
    expect(suggest([base], meal: Meal.dinner, count: 3, tools: {Tool.kettle}), isEmpty);
    expect(ids(suggest([base], meal: Meal.dinner, count: 3)), ['base']);
  });

  test('ít thiếu ưu tiên hơn đã lưu; hòa thì lưu, chê, vừa nấu, đúng bữa, vị trí', () {
    final list = [
      _recipe('missing', [Meal.dinner]),
      _recipe('ready', [Meal.dinner]),
      _recipe('saved', [Meal.dinner]),
      _recipe('disliked', [Meal.dinner]),
      _recipe('cooked', [Meal.dinner]),
      _recipe('general', []),
    ];
    final stock = {'egg'};
    final ingredients = <String, Ingredient>{};
    expect(
      ids(
        suggest(
          list,
          meal: Meal.dinner,
          count: 9,
          pantry: stock,
          ingredientsById: ingredients,
          saved: {'saved'},
          disliked: {'disliked'},
          recentlyCooked: {'cooked'},
        ),
      ),
      ['saved', 'missing', 'ready', 'general', 'cooked'],
    );
    expect(ids(suggest(list, meal: Meal.dinner, count: 2)), ['missing', 'ready']);
    final ready = Recipe(
      id: 'enough',
      name: '',
      description: '',
      imageAsset: '',
      minutes: 5,
      servings: 1,
      tools: const [],
      diets: const [],
      meals: const [Meal.dinner],
      ingredients: const [],
      steps: const [],
    );
    expect(ids(suggest([list.first, ready], meal: Meal.dinner, count: 2, saved: {'missing'})), [
      'enough',
      'missing',
    ]);
  });

  test('lý do chỉ nêu đủ đồ khi thực sự đủ; không tự bịa dụng cụ', () {
    final recipe = _recipe('reason', [Meal.dinner]);
    expect(suggestionReason(recipe, const Availability()), 'Đủ đồ, 10 phút, bếp từ');
    expect(
      suggestionReason(recipe, const Availability(missing: ['trứng'])),
      'Thiếu 1 thứ, 10 phút, bếp từ',
    );
    final noTool = Recipe(
      id: 'none',
      name: '',
      description: '',
      imageAsset: '',
      minutes: 4,
      servings: 1,
      tools: const [],
      diets: const [],
      meals: const [],
      ingredients: const [],
      steps: const [],
    );
    expect(suggestionReason(noTool, const Availability()), 'Đủ đồ, 4 phút');
  });

  test('dữ liệu rỗng, count không dương và thứ tự hòa điểm', () {
    expect(suggest([], meal: Meal.dinner, count: 2), isEmpty);
    expect(suggest(recipes, meal: Meal.dinner, count: 0), isEmpty);
    expect(ids(suggest([_recipe('a', []), _recipe('b', [])], meal: Meal.dinner, count: 5)), [
      'a',
      'b',
    ]);
  });
}
