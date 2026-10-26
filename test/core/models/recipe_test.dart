import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';

void main() {
  group('scaleAmount', () {
    test('nhân đúng theo khẩu phần', () {
      expect(scaleAmount(3, 2, 4), 6.0);
      expect(scaleAmount(100, 1, 2), 200.0);
    });

    test('khẩu phần gốc <= 0 trả về nguyên', () {
      expect(scaleAmount(5, 0, 3), 5.0);
    });

    test('khẩu phần mục tiêu 0 cho 0', () {
      expect(scaleAmount(4, 2, 0), 0.0);
    });
  });

  group('Recipe.fromJson', () {
    test('parse công thức mẫu', () {
      final json = <String, dynamic>{
        'id': 'r1',
        'name': 'Món test',
        'description': 'Mô tả',
        'imageAsset': 'assets/images/recipes/r1.jpg',
        'minutes': 10,
        'servings': 2,
        'tools': ['stove'],
        'diets': ['veg'],
        'meals': ['breakfast'],
        'ingredients': [
          {'id': 'egg', 'amount': 2, 'unit': 'quả'},
        ],
        'steps': [
          {'text': 'Bước 1', 'timerSeconds': 60},
        ],
      };
      final recipe = Recipe.fromJson(json);
      expect(recipe.id, 'r1');
      expect(recipe.tools, [Tool.stove]);
      expect(recipe.diets, [Diet.veg]);
      expect(recipe.meals, [Meal.breakfast]);
      expect(recipe.ingredients.first.amount, 2);
      expect(recipe.steps.first.timerSeconds, 60);

      final scaled = scaleIngredients(recipe, 4);
      expect(scaled.first.amount, 4.0);

      expect(Recipe.fromJson(json), recipe);
      expect(Recipe.fromJson(json).hashCode, recipe.hashCode);
      expect(Recipe.fromJson(recipe.toJson()), recipe);
      expect(() => recipe.tools.add(Tool.micro), throwsUnsupportedError);
      expect(() => recipe.ingredients.clear(), throwsUnsupportedError);
    });

    test('id lạ ném FormatException kèm id món', () {
      Map<String, dynamic> withField(String key, List<String> value) => <String, dynamic>{
        'id': 'r1',
        'name': 'Món test',
        'imageAsset': 'assets/images/recipes/r1.jpg',
        'minutes': 10,
        'servings': 2,
        'tools': ['stove'],
        'ingredients': <Object>[],
        'steps': <Object>[],
        key: value,
      };
      Matcher fails(String message) =>
          throwsA(isA<FormatException>().having((e) => e.message, 'message', message));

      expect(
        () => Recipe.fromJson(withField('tools', ['stoev'])),
        fails('Món "r1": dụng cụ "stoev" không có'),
      );
      expect(
        () => Recipe.fromJson(withField('diets', ['vegan'])),
        fails('Món "r1": chế độ ăn "vegan" không có'),
      );
      expect(
        () => Recipe.fromJson(withField('meals', ['brunch'])),
        fails('Món "r1": bữa "brunch" không có'),
      );
    });
  });

  group('RecipeStep', () {
    test('prep mặc định false, chỉ ghi ra JSON khi true', () {
      final step = RecipeStep.fromJson(<String, dynamic>{'text': 'Chiên', 'timerSeconds': 60});
      expect(step.prep, isFalse);
      expect(step.toJson(), {'text': 'Chiên', 'timerSeconds': 60});

      final prep = RecipeStep.fromJson(<String, dynamic>{'text': 'Thái hành', 'prep': true});
      expect(prep.prep, isTrue);
      expect(prep.toJson(), {'text': 'Thái hành', 'prep': true});
      expect(RecipeStep.fromJson(prep.toJson()), prep);
      expect(prep, isNot(const RecipeStep(text: 'Thái hành')));
      expect(prep.hashCode, const RecipeStep(text: 'Thái hành', prep: true).hashCode);
    });
  });

  group('gatherIngredients', () {
    Recipe recipe(String id, int servings, List<RecipeIngredient> ingredients) => Recipe(
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
    final trung = recipe('trung', 1, const [
      RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
      RecipeIngredient(id: 'scallion', amount: 1, unit: 'nhánh'),
    ]);
    final canh = recipe('canh', 2, const [
      RecipeIngredient(id: 'tomato', amount: 2, unit: 'quả'),
      RecipeIngredient(id: 'egg', amount: 1, unit: 'quả'),
      RecipeIngredient(id: 'scallion', amount: 10, unit: 'g'),
    ]);
    final byId = {trung.id: trung, canh.id: canh};

    test('cộng lượng theo khẩu phần, khác đơn vị tách dòng, giữ thứ tự gặp đầu', () {
      final lines = gatherIngredients([
        (recipeId: 'trung', servings: 2),
        (recipeId: 'canh', servings: 4),
      ], byId);
      expect(lines, const [
        GatheredIngredient(
          ingredientId: 'egg',
          unit: 'quả',
          amount: 6,
          recipeIds: ['trung', 'canh'],
        ),
        GatheredIngredient(
          ingredientId: 'scallion',
          unit: 'nhánh',
          amount: 2,
          recipeIds: ['trung'],
        ),
        GatheredIngredient(ingredientId: 'tomato', unit: 'quả', amount: 4, recipeIds: ['canh']),
        GatheredIngredient(ingredientId: 'scallion', unit: 'g', amount: 20, recipeIds: ['canh']),
      ]);
    });

    test('món lạ bị bỏ qua, cùng món hai lần không lặp id', () {
      final lines = gatherIngredients([
        (recipeId: 'trung', servings: 1),
        (recipeId: 'khong-co', servings: 1),
        (recipeId: 'trung', servings: 1),
      ], byId);
      expect(
        lines.first,
        const GatheredIngredient(
          ingredientId: 'egg',
          unit: 'quả',
          amount: 4,
          recipeIds: ['trung'],
        ),
      );
      expect(lines, hasLength(2));
    });
  });

  group('enum', () {
    test('tryParse trả null cho id lạ (dữ liệu cũ trong LocalStore)', () {
      expect(Tool.tryParse('stoev'), isNull);
      expect(Diet.tryParse('veg'), Diet.veg);
    });
  });

  group('Ingredient.fromJson', () {
    test('parse nguyên liệu', () {
      final ing = Ingredient.fromJson(<String, dynamic>{
        'id': 'egg',
        'name': 'Trứng',
        'group': 'protein',
        'isBasicSpice': false,
      });
      expect(ing.group, IngredientGroup.protein);
      expect(ing.isBasicSpice, false);
    });

    test('group thiếu hoặc lạ là lỗi, không rơi về other', () {
      Matcher fails(String message) =>
          throwsA(isA<FormatException>().having((e) => e.message, 'message', message));
      expect(
        () => Ingredient.fromJson(<String, dynamic>{'id': 'egg', 'name': 'Trứng', 'group': 'meat'}),
        fails('Nguyên liệu "egg": nhóm nguyên liệu "meat" không có'),
      );
      expect(
        () => Ingredient.fromJson(<String, dynamic>{'id': 'egg', 'name': 'Trứng'}),
        fails('Nguyên liệu "egg": nhóm nguyên liệu "" không có'),
      );
    });
  });
}
