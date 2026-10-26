import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

import 'fixtures.dart';

void main() {
  final byId = {for (final i in cookIngredientsFixture) i.id: i};

  test('mọi nguyên liệu một dòng kèm lượng theo khẩu phần, gia vị gom riêng', () {
    final result = stepIngredients(cookRecipeFixture, 2, byId);

    expect(result.items, [
      (name: 'Trứng gà', amountText: '4 quả'),
      (name: 'Hành lá', amountText: '2 nắm'),
      (name: 'Ớt', amountText: '1 quả'),
    ]);
    expect(result.basicSpices, ['Dầu ăn', 'tiêu']);
  });

  test('key hẹn giờ khác nhau theo món và bước, nằm trong khoảng cho phép', () {
    final keys = {
      for (var dish = 0; dish < 3; dish++)
        for (var step = 0; step < maxStepsPerDish; step++) cookTimerKey(dish, step),
    };
    expect(keys, hasLength(3 * maxStepsPerDish));
    expect(keys.every((k) => k >= 0 && k <= maxTimerKey), isTrue);
  });
}
