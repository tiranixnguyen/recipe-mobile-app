import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/domain/recipe_detail.dart';

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

Recipe _recipe(List<RecipeIngredient> ingredients) => Recipe(
  id: 'trung',
  name: 'Trứng chiên hành',
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: ingredients,
  steps: const [],
);

void main() {
  group('detailIngredients', () {
    test('có trong tủ, thiếu, tuỳ chọn; gia vị cơ bản gom một dòng theo thứ tự công thức', () {
      final recipe = _recipe(const [
        RecipeIngredient(id: 'egg', amount: 2, unit: 'quả'),
        RecipeIngredient(id: 'oil', amount: 1, unit: 'muỗng canh'),
        RecipeIngredient(id: 'scallion', amount: 1.5, unit: 'nhánh'),
        RecipeIngredient(id: 'fishsauce', amount: 1, unit: 'muỗng canh', optional: true),
        RecipeIngredient(id: 'tomato', amount: 1, unit: 'quả', optional: true),
      ]);

      final (:items, :basicSpices) = detailIngredients(recipe, {'egg'}, _ingredients);

      expect(items, const [
        DetailIngredient(name: 'Trứng gà', amountText: '2 quả', status: IngredientStatus.inPantry),
        DetailIngredient(
          name: 'Hành lá',
          amountText: '1,5 nhánh',
          status: IngredientStatus.missing,
        ),
        DetailIngredient(name: 'Cà chua', amountText: '1 quả', status: IngredientStatus.optional),
      ]);
      expect(basicSpices, ['Dầu ăn', 'nước mắm']);
    });

    test('tuỳ chọn mà có trong tủ thì là Có trong tủ', () {
      final recipe = _recipe(const [
        RecipeIngredient(id: 'tomato', amount: 1, unit: 'quả', optional: true),
      ]);
      expect(
        detailIngredients(recipe, {'tomato'}, _ingredients).items.single.status,
        IngredientStatus.inPantry,
      );
    });

    test('id lạ hiện bằng id, không coi là gia vị', () {
      final recipe = _recipe(const [RecipeIngredient(id: 'xyz', amount: 100, unit: 'g')]);
      final (:items, :basicSpices) = detailIngredients(recipe, {}, _ingredients);
      expect(
        items.single,
        const DetailIngredient(
          name: 'xyz',
          amountText: '100 g',
          status: IngredientStatus.missing,
        ),
      );
      expect(basicSpices, isEmpty);
    });
  });

  test('stepTimeLabel', () {
    expect(stepTimeLabel(const RecipeStep(text: 'a')), isNull);
    expect(stepTimeLabel(const RecipeStep(text: 'a', timerSeconds: 0)), isNull);
    expect(stepTimeLabel(const RecipeStep(text: 'a', timerSeconds: 45)), '45 giây');
    expect(stepTimeLabel(const RecipeStep(text: 'a', timerSeconds: 60)), '1 phút');
    expect(stepTimeLabel(const RecipeStep(text: 'a', timerSeconds: 90)), '1 phút 30 giây');
    expect(stepTimeLabel(const RecipeStep(text: 'a', timerSeconds: 600)), '10 phút');
  });
}
