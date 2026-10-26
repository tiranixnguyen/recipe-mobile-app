import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/domain/meal_cook.dart';

const _ingredients = {
  'egg': Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein),
  'scallion': Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  'tomato': Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
  'oil': Ingredient(id: 'oil', name: 'Dầu ăn', group: IngredientGroup.spice, isBasicSpice: true),
  'fishsauce': Ingredient(
    id: 'fishsauce',
    name: 'Nước mắm',
    group: IngredientGroup.spice,
    isBasicSpice: true,
  ),
};

Recipe _recipe(
  String id, {
  int minutes = 10,
  int servings = 1,
  List<RecipeIngredient> ingredients = const [],
  List<RecipeStep> steps = const [],
}) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: '',
  minutes: minutes,
  servings: servings,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: ingredients,
  steps: steps,
);

final _trung = _recipe(
  'trung',
  minutes: 15,
  ingredients: const [
    RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'scallion', amount: 1, unit: 'nhánh'),
    RecipeIngredient(id: 'oil', amount: 1, unit: 'muỗng canh'),
  ],
  steps: const [
    RecipeStep(text: 'Thái hành.', prep: true),
    RecipeStep(text: 'Đánh trứng.', prep: true),
    RecipeStep(text: 'Làm nóng dầu.', timerSeconds: 60),
    RecipeStep(text: 'Chiên trứng.', timerSeconds: 120),
  ],
);

/// Công thức cho 2 người.
final _canh = _recipe(
  'canh',
  minutes: 20,
  servings: 2,
  ingredients: const [
    RecipeIngredient(id: 'tomato', amount: 2, unit: 'quả'),
    RecipeIngredient(id: 'egg', amount: 1, unit: 'quả'),
    RecipeIngredient(id: 'scallion', amount: 10, unit: 'g'),
    RecipeIngredient(id: 'fishsauce', amount: 1, unit: 'muỗng canh'),
    RecipeIngredient(id: 'oil', amount: 1, unit: 'muỗng cà phê'),
  ],
  steps: const [
    RecipeStep(text: 'Cà chua bổ múi cau.', prep: true),
    RecipeStep(text: 'Đun sôi nước.', timerSeconds: 300),
  ],
);

final _banhMi = _recipe(
  'banh-mi',
  minutes: 15,
  ingredients: const [RecipeIngredient(id: 'bread', amount: 1, unit: 'ổ')],
  steps: const [RecipeStep(text: 'Ốp trứng.', timerSeconds: 150)],
);

void main() {
  group('suggestCookOrder', () {
    test('món lâu trước, bằng phút giữ thứ tự thêm', () {
      final order = suggestCookOrder([
        (recipe: _trung, servings: 1),
        (recipe: _banhMi, servings: 1),
        (recipe: _canh, servings: 2),
      ]);
      expect(order.map((d) => d.recipe.id), ['canh', 'trung', 'banh-mi']);

      final swapped = suggestCookOrder([
        (recipe: _banhMi, servings: 1),
        (recipe: _trung, servings: 1),
      ]);
      expect(swapped.map((d) => d.recipe.id), ['banh-mi', 'trung']);
    });

    test('giữ khẩu phần của từng món', () {
      final order = suggestCookOrder([(recipe: _trung, servings: 3), (recipe: _canh, servings: 4)]);
      expect(order.map((d) => d.servings), [4, 3]);
    });
  });

  group('mealPrepTasks', () {
    test('bước prep theo thứ tự nấu rồi thứ tự trong món, giữ chỉ số gốc', () {
      final tasks = mealPrepTasks([
        (recipe: _canh, servings: 2),
        (recipe: _banhMi, servings: 1),
        (recipe: _trung, servings: 1),
      ]);
      expect(tasks, const [
        MealPrepTask(recipeId: 'canh', stepIndex: 0, text: 'Cà chua bổ múi cau.'),
        MealPrepTask(recipeId: 'trung', stepIndex: 0, text: 'Thái hành.'),
        MealPrepTask(recipeId: 'trung', stepIndex: 1, text: 'Đánh trứng.'),
      ]);
    });

    test('không món nào có prep thì rỗng', () {
      expect(mealPrepTasks([(recipe: _banhMi, servings: 1)]), isEmpty);
    });
  });

  group('cookSteps', () {
    test('bỏ bước prep, giữ chỉ số gốc làm khoá hẹn giờ', () {
      final steps = cookSteps(_trung);
      expect(steps.map((s) => s.index), [2, 3]);
      expect(steps.map((s) => s.step.text), ['Làm nóng dầu.', 'Chiên trứng.']);
    });

    test('món không có prep giữ nguyên', () {
      expect(cookSteps(_banhMi), [(index: 0, step: _banhMi.steps.first)]);
    });
  });

  group('mealGatherList', () {
    test('cộng lượng trùng theo khẩu phần, khác đơn vị tách dòng, gia vị gom một dòng', () {
      final list = mealGatherList([
        (recipe: _canh, servings: 4),
        (recipe: _trung, servings: 2),
      ], _ingredients);
      expect(list.items, const [
        MealGatherItem(
          ingredientId: 'tomato',
          name: 'Cà chua',
          amountText: '4 quả',
          recipeIds: ['canh'],
        ),
        MealGatherItem(
          ingredientId: 'egg',
          name: 'Trứng gà',
          amountText: '6 quả',
          recipeIds: ['canh', 'trung'],
        ),
        MealGatherItem(
          ingredientId: 'scallion',
          name: 'Hành lá',
          amountText: '20 g',
          recipeIds: ['canh'],
        ),
        MealGatherItem(
          ingredientId: 'scallion',
          name: 'Hành lá',
          amountText: '2 nhánh',
          recipeIds: ['trung'],
        ),
      ]);
      // Dầu ăn có hai đơn vị (muỗng cà phê, muỗng canh) vẫn chỉ một tên.
      expect(list.basicSpices, ['Nước mắm', 'dầu ăn']);
    });

    test('id lạ hiện bằng id, lượng lẻ dùng dấu phẩy', () {
      final list = mealGatherList([(recipe: _banhMi, servings: 1)], _ingredients);
      expect(list.items.single.name, 'bread');
      expect(list.basicSpices, isEmpty);

      final half = mealGatherList([(recipe: _canh, servings: 1)], _ingredients);
      expect(half.items.map((i) => i.amountText), ['1 quả', '0,5 quả', '5 g']);
    });
  });
}
