import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_prep.dart';

import 'fixtures.dart';

void main() {
  final byId = {for (final i in cookIngredientsFixture) i.id: i};

  test('đồ có trong tủ thành dòng kèm lượng, gia vị gom một dòng, thiếu kèm ghi chú', () {
    final result = prepItems(cookRecipeFixture, 1, {'egg'}, byId);

    expect(result.gather, [const PrepItem(ingredientId: 'egg', label: 'Trứng gà · 2 quả')]);
    expect(result.basicSpices, ['Dầu ăn', 'tiêu']);
    expect(result.missing, [
      const PrepMissing(ingredientId: 'scallion', name: 'hành lá'),
      const PrepMissing(
        ingredientId: 'chili',
        name: 'ớt',
        note: 'Không có cũng được, hoặc thay bằng chút ớt bột.',
      ),
    ]);
  });

  test('lượng nhân theo khẩu phần, số lẻ dùng dấu phẩy', () {
    final result = prepItems(cookRecipeFixture, 3, {'egg', 'chili'}, byId);

    expect(result.gather.map((i) => i.label), ['Trứng gà · 6 quả', 'Ớt · 1,5 quả']);
    expect(result.missing.map((m) => m.ingredientId), ['scallion']);
  });

  test('id không có trong danh mục thì hiện bằng id', () {
    final result = prepItems(cookRecipeFixture, 1, {'egg'}, const {});

    expect(result.basicSpices, isEmpty);
    expect(result.gather.single.label, 'egg · 2 quả');
    expect(result.missing.map((m) => m.name), ['scallion', 'oil', 'pepper', 'chili']);
  });
}
