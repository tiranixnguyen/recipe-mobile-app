import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/domain/meal_detail.dart';

const _ingredients = {
  'tofu': Ingredient(id: 'tofu', name: 'Đậu phụ', group: IngredientGroup.protein),
  'tomato': Ingredient(id: 'tomato', name: 'Cà chua', group: IngredientGroup.vegetable),
  'scallion': Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  'chili': Ingredient(id: 'chili', name: 'Ớt', group: IngredientGroup.vegetable),
  'oil': Ingredient(id: 'oil', name: 'Dầu ăn', group: IngredientGroup.spice, isBasicSpice: true),
  'salt': Ingredient(id: 'salt', name: 'Muối', group: IngredientGroup.spice, isBasicSpice: true),
};

Recipe _recipe(
  String id,
  String name,
  List<RecipeIngredient> ingredients, {
  DishRole role = DishRole.main,
}) => Recipe(
  id: id,
  name: name,
  description: '',
  imageAsset: '',
  minutes: 15,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: ingredients,
  steps: const [],
  role: role,
);

final _tofu = _recipe('tofu', 'Đậu phụ sốt cà chua', const [
  RecipeIngredient(id: 'tofu', amount: 2, unit: 'bìa'),
  RecipeIngredient(id: 'tomato', amount: 2, unit: 'quả'),
  RecipeIngredient(id: 'scallion', amount: 1, unit: 'nắm'),
  RecipeIngredient(id: 'chili', amount: 1, unit: 'quả', optional: true),
  RecipeIngredient(id: 'oil', amount: 1, unit: 'muỗng canh'),
]);
final _soup = _recipe('soup', 'Canh cà chua', const [
  RecipeIngredient(id: 'tomato', amount: 1, unit: 'quả'),
  RecipeIngredient(id: 'scallion', amount: 1, unit: 'nắm'),
  RecipeIngredient(id: 'salt', amount: 1, unit: 'nhúm'),
  RecipeIngredient(id: 'oil', amount: 1, unit: 'muỗng canh'),
], role: DishRole.soup);

void main() {
  group('mergeMealIngredients', () {
    test('cộng theo nguyên liệu và khẩu phần, chia thiếu / có trong tủ, uses', () {
      final merged = mergeMealIngredients([_tofu, _soup], 2, {'tomato'}, _ingredients, {});

      expect(merged.missing.map((m) => (m.name, m.amountText, m.uses)), [
        ('Đậu phụ', '4 bìa', 'Đậu phụ sốt cà chua'),
        ('Hành lá', '4 nắm', 'Cả 2 món'),
      ]);
      expect(merged.have.map((m) => (m.name, m.amountText, m.uses)), [
        ('Cà chua', '6 quả', 'Cả 2 món'),
      ]);
    });

    test('gia vị cơ bản gom một dòng không trùng; nguyên liệu tuỳ chọn không tính là thiếu', () {
      final merged = mergeMealIngredients([_tofu, _soup], 1, {}, _ingredients, {});

      expect(merged.basicSpices, ['Dầu ăn', 'muối']);
      expect(merged.optional.map((m) => m.name), ['Ớt']);
      expect(merged.missing.map((m) => m.name), isNot(contains('Ớt')));
      expect(merged.missing.map((m) => m.name), isNot(contains('Dầu ăn')));
    });

    test('tuỳ chọn ở món này nhưng bắt buộc ở món kia thì vẫn là thiếu', () {
      final other = _recipe('other', 'Món khác', const [
        RecipeIngredient(id: 'chili', amount: 2, unit: 'quả'),
      ]);
      final merged = mergeMealIngredients([_tofu, other], 1, {}, _ingredients, {});
      expect(merged.missing.map((m) => (m.name, m.amountText)), contains(('Ớt', '3 quả')));
      expect(merged.optional, isEmpty);
    });

    test('dòng thiếu đã trong đi chợ thì inShopping', () {
      final merged = mergeMealIngredients([_tofu, _soup], 1, {}, _ingredients, {'tofu'});
      expect(
        {for (final m in merged.missing) m.name: m.inShopping},
        {'Đậu phụ': true, 'Cà chua': false, 'Hành lá': false},
      );
    });

    test('id lạ hiện bằng id; bữa trống ra rỗng', () {
      final odd = _recipe('odd', 'Món lạ', const [
        RecipeIngredient(id: 'xyz', amount: 100, unit: 'g'),
      ]);
      expect(
        mergeMealIngredients([odd], 1, {}, _ingredients, {}).missing.single.name,
        'xyz',
      );
      final empty = mergeMealIngredients([], 1, {}, _ingredients, {});
      expect(empty.missing, isEmpty);
      expect(empty.have, isEmpty);
      expect(empty.basicSpices, isEmpty);
    });
  });

  group('filterPickerRecipes', () {
    final side = _recipe('rau', 'Rau muống xào tỏi', const [], role: DishRole.side);
    final egg = _recipe('trung', 'Trứng chiên hành', const []);
    final all = [_tofu, _soup, side, egg];

    test('đã lưu trước, mỗi nhóm xếp theo tên', () {
      final lists = filterPickerRecipes(all, savedIds: {'trung', 'rau'});
      expect(lists.saved.map((r) => r.id), ['rau', 'trung']);
      expect(lists.others.map((r) => r.id), ['soup', 'tofu']);
    });

    test('lọc theo vai món và từ khoá không dấu', () {
      expect(
        filterPickerRecipes(all, savedIds: {}, role: DishRole.soup).others.map((r) => r.id),
        ['soup'],
      );
      expect(
        filterPickerRecipes(all, savedIds: {'trung'}, query: ' TRUNG ').saved.map((r) => r.id),
        ['trung'],
      );
      expect(filterPickerRecipes(all, savedIds: {}, query: 'ca chua').others.map((r) => r.id), [
        'soup',
        'tofu',
      ]);
      final none = filterPickerRecipes(all, savedIds: {}, query: 'zzz');
      expect(none.saved, isEmpty);
      expect(none.others, isEmpty);
    });
  });
}
