import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';

const _byId = {
  'egg': Ingredient(id: 'egg', name: 'Trứng gà', group: IngredientGroup.protein),
  'scallion': Ingredient(id: 'scallion', name: 'Hành lá', group: IngredientGroup.vegetable),
  'oil': Ingredient(id: 'oil', name: 'Dầu ăn', group: IngredientGroup.spice, isBasicSpice: true),
};

const _fried = Recipe(
  id: 'fried',
  name: 'Trứng chiên',
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: [],
  diets: [],
  meals: [],
  ingredients: [],
  steps: [],
);

ShoppingSheet _sheet({
  List<ShoppingLine> lines = const [],
  List<({String? ingredientId, String? name})> items = const [],
  Set<String> pantry = const {},
}) => buildShoppingSheet(
  lines: lines,
  items: items,
  ingredientsById: _byId,
  recipesById: {'fried': _fried},
  pantry: pantry,
);

List<String> _names(ShoppingSheet s) => [
  for (final g in s.groups)
    for (final r in g.rows) r.name,
];

void main() {
  const egg = ShoppingLine(ingredientId: 'egg', unit: 'quả', amount: 2, recipeIds: ['fried']);
  const scallion = ShoppingLine(
    ingredientId: 'scallion',
    unit: 'nắm',
    amount: 1.5,
    recipeIds: ['fried', 'khong-co'],
  );
  const oil = ShoppingLine(ingredientId: 'oil', unit: 'muỗng', amount: 1, recipeIds: ['fried']);

  test('nhóm Rau củ trước Đạm, lượng kiểu Việt, món dùng bỏ id lạ', () {
    final sheet = _sheet(lines: [egg, scallion]);
    expect(
      [for (final g in sheet.groups) g.group],
      [
        IngredientGroup.vegetable,
        IngredientGroup.protein,
      ],
    );
    expect(_names(sheet), ['Hành lá · 1,5 nắm', 'Trứng gà · 2 quả']);
    expect(sheet.groups.first.rows.single.uses, 'Trứng chiên');
    expect(sheet.groups.first.rows.single.id, 'line:scallion:nắm');
  });

  test('bỏ gia vị cơ bản; trừ Tủ đồ và ghi tên thứ đã bỏ một lần', () {
    final sheet = _sheet(lines: [egg, egg, oil], pantry: {'egg'});
    expect(sheet.groups, isEmpty);
    expect(sheet.inPantry, ['trứng gà']);
  });

  test('đồ tự thêm: trùng nguyên liệu của thực đơn thì gộp; có trong tủ thì trừ', () {
    final sheet = _sheet(
      lines: [egg],
      items: [
        (ingredientId: 'egg', name: null),
        (ingredientId: 'scallion', name: null),
      ],
      pantry: {'scallion'},
    );
    expect(_names(sheet), ['Trứng gà · 2 quả']);
    expect(sheet.inPantry, ['hành lá']);
  });

  test('tên tự gõ vào nhóm Khác, không trùng tên nguyên liệu đã có (không phân biệt dấu)', () {
    final sheet = _sheet(
      lines: [egg],
      items: [
        (ingredientId: null, name: 'trung ga'),
        (ingredientId: null, name: 'Giấy ăn'),
        (ingredientId: null, name: 'giay an'),
      ],
    );
    expect(_names(sheet), ['Trứng gà · 2 quả', 'Giấy ăn']);
    final other = sheet.groups.last;
    expect(
      (other.group, other.rows.single.ingredientId, other.rows.single.uses),
      (
        IngredientGroup.other,
        null,
        null,
      ),
    );
  });
}
