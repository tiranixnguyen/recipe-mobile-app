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
    RecipeStep(text: 'Thái hành.'),
    RecipeStep(text: 'Đánh trứng.'),
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
    RecipeStep(text: 'Cà chua bổ múi cau.'),
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

  group('mealPrepItems', () {
    test('đồ có trong tủ cộng cho cả bữa, đồ thiếu mỗi thứ một lần kèm ghi chú', () {
      final ot = _recipe(
        'ot',
        ingredients: const [
          RecipeIngredient(
            id: 'chili',
            amount: 1,
            unit: 'quả',
            optional: true,
            substituteNote: 'Không có cũng được.',
          ),
        ],
      );
      final result = mealPrepItems(
        [(recipe: _canh, servings: 2), (recipe: _trung, servings: 1), (recipe: ot, servings: 1)],
        {'egg'},
        _ingredients,
      );

      expect(result.gather.map((i) => (i.name, i.amountText)), [('Trứng gà', '3 quả')]);
      expect(result.gather.single.recipeIds, ['canh', 'trung']);
      expect(result.basicSpices, ['Nước mắm', 'dầu ăn']);
      expect(result.missing.map((m) => (m.ingredientId, m.note)), [
        ('tomato', null),
        ('scallion', null),
        ('chili', 'Không có cũng được.'),
      ]);
    });
  });

  group('mealPrepTasks', () {
    /// Hành lá chỉ cắt khúc 1 trong 2 nhánh (`amount`), món trứng thái nhỏ cả nhánh.
    final dau = _recipe(
      'dau',
      minutes: 20,
      servings: 2,
      ingredients: const [
        RecipeIngredient(id: 'garlic', amount: 2, unit: 'tép'),
        RecipeIngredient(id: 'scallion', amount: 2, unit: 'nhánh'),
        RecipeIngredient(id: 'tomato', amount: 2, unit: 'quả'),
      ],
      steps: const [
        RecipeStep(
          text: 'Cà chua bổ múi cau. Tỏi băm. Hành lá cắt khúc.',
          prep: [
            PrepTask(id: 'tomato', action: 'Bổ múi cau'),
            PrepTask(id: 'garlic', action: 'Băm nhỏ'),
            PrepTask(id: 'scallion', action: 'Cắt khúc', amount: 1),
          ],
        ),
        RecipeStep(text: 'Xào.', timerSeconds: 120),
      ],
    );
    final trung = _recipe(
      'trung',
      ingredients: const [
        RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
        RecipeIngredient(id: 'garlic', amount: 1, unit: 'tép'),
        RecipeIngredient(id: 'scallion', amount: 1, unit: 'nhánh'),
      ],
      steps: const [
        RecipeStep(
          text: 'Tỏi băm, hành thái nhỏ.',
          prep: [
            PrepTask(id: 'garlic', action: 'Băm nhỏ'),
            PrepTask(id: 'scallion', action: 'Thái nhỏ'),
          ],
        ),
        RecipeStep(
          text: 'Đánh trứng.',
          prep: [PrepTask(id: 'egg', action: 'Đánh tan')],
        ),
        RecipeStep(text: 'Chiên.', timerSeconds: 120),
      ],
    );

    test('một món: mỗi việc một dòng, lượng cả món hoặc một phần, giữ thứ tự', () {
      final tasks = mealPrepTasks([(recipe: dau, servings: 2)]);
      expect(tasks, const [
        MealPrepTask(
          id: 'tomato',
          ingredientId: 'tomato',
          action: 'Bổ múi cau',
          amount: 2,
          unit: 'quả',
          shares: [(recipeId: 'dau', amount: 2)],
        ),
        MealPrepTask(
          id: 'garlic',
          ingredientId: 'garlic',
          action: 'Băm nhỏ',
          amount: 2,
          unit: 'tép',
          shares: [(recipeId: 'dau', amount: 2)],
        ),
        MealPrepTask(
          id: 'scallion',
          ingredientId: 'scallion',
          action: 'Cắt khúc',
          amount: 1,
          unit: 'nhánh',
          shares: [(recipeId: 'dau', amount: 1)],
        ),
      ]);
      expect(prepLeafIds(tasks), ['tomato', 'garlic', 'scallion']);
    });

    test('nhiều món cùng cách làm: một việc, cộng lượng, giữ phần từng món theo thứ tự nấu', () {
      final tasks = mealPrepTasks([(recipe: dau, servings: 2), (recipe: trung, servings: 1)]);
      final garlic = tasks.firstWhere((t) => t.ingredientId == 'garlic');
      expect(garlic.action, 'Băm nhỏ');
      expect(garlic.amount, 3);
      expect(garlic.shares, [(recipeId: 'dau', amount: 2.0), (recipeId: 'trung', amount: 1.0)]);
      expect(garlic.isParent, isFalse);
    });

    test('nhiều món khác cách làm: việc cha tổng lượng, việc con theo cách làm', () {
      final tasks = mealPrepTasks([(recipe: dau, servings: 2), (recipe: trung, servings: 1)]);
      expect(tasks.map((t) => t.id), ['tomato', 'garlic', 'scallion', 'egg']);

      final scallion = tasks[2];
      expect(scallion.isParent, isTrue);
      expect(scallion.action, isEmpty);
      expect(scallion.shares, isEmpty);
      expect(scallion.amount, 2);
      expect(scallion.children, const [
        MealPrepTask(
          id: 'scallion/Cắt khúc',
          ingredientId: 'scallion',
          action: 'Cắt khúc',
          amount: 1,
          unit: 'nhánh',
          shares: [(recipeId: 'dau', amount: 1)],
        ),
        MealPrepTask(
          id: 'scallion/Thái nhỏ',
          ingredientId: 'scallion',
          action: 'Thái nhỏ',
          amount: 1,
          unit: 'nhánh',
          shares: [(recipeId: 'trung', amount: 1)],
        ),
      ]);
      expect(prepLeafIds(tasks), [
        'tomato',
        'garlic',
        'scallion/Cắt khúc',
        'scallion/Thái nhỏ',
        'egg',
      ]);
    });

    test('nhân lượng theo khẩu phần', () {
      final tasks = mealPrepTasks([(recipe: dau, servings: 4), (recipe: trung, servings: 3)]);
      final garlic = tasks.firstWhere((t) => t.ingredientId == 'garlic');
      expect(garlic.shares, [(recipeId: 'dau', amount: 4.0), (recipeId: 'trung', amount: 3.0)]);
      expect(garlic.amount, 7);
      final scallion = tasks.firstWhere((t) => t.ingredientId == 'scallion');
      expect(scallion.children.map((c) => c.amount), [2, 3]);
      expect(scallion.amount, 5);
    });

    test('món không có bước sơ chế: rỗng; id lạ bỏ qua', () {
      expect(mealPrepTasks([(recipe: _banhMi, servings: 1)]), isEmpty);
      expect(prepLeafIds(const []), isEmpty);

      final odd = _recipe(
        'odd',
        steps: const [
          RecipeStep(
            text: 'Thái.',
            prep: [PrepTask(id: 'ghost', action: 'Thái')],
          ),
        ],
      );
      expect(mealPrepTasks([(recipe: odd, servings: 1)]), isEmpty);
    });

    test('một nguyên liệu hai đơn vị trong bữa: khoá thêm đơn vị', () {
      final canh = _recipe(
        'canh',
        ingredients: const [RecipeIngredient(id: 'scallion', amount: 10, unit: 'g')],
        steps: const [
          RecipeStep(
            text: 'Thái hành.',
            prep: [PrepTask(id: 'scallion', action: 'Thái nhỏ')],
          ),
        ],
      );
      final tasks = mealPrepTasks([(recipe: trung, servings: 1), (recipe: canh, servings: 1)]);
      final ids = prepLeafIds(tasks);
      expect(ids, ['garlic', 'scallion@nhánh', 'egg', 'scallion@g']);
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('cookSteps', () {
    test('bỏ bước sơ chế, giữ chỉ số gốc', () {
      final recipe = _recipe(
        'r',
        steps: const [
          RecipeStep(
            text: 'Thái.',
            prep: [PrepTask(id: 'egg', action: 'Thái')],
          ),
          RecipeStep(text: 'Chiên.', timerSeconds: 60),
          RecipeStep(text: 'Bày ra đĩa.'),
        ],
      );
      expect(cookSteps(recipe).map((s) => s.index), [1, 2]);
      expect(cookSteps(_trung).map((s) => s.index), [0, 1, 2, 3]);
    });
  });
}
