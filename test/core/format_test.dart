import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';

void main() {
  test('formatAmount bỏ số 0 thừa, dùng dấu phẩy, tối đa 2 chữ số lẻ', () {
    expect(formatAmount(4), '4');
    expect(formatAmount(1.5), '1,5');
    expect(formatAmount(1 / 3), '0,33');
    expect(formatAmount(100), '100');
  });

  test('recipeMeta: phút · (người) · dụng cụ đầu tiên, nhãn ngắn', () {
    Recipe recipe(List<Tool> tools) => Recipe(
      id: 'a',
      name: 'A',
      description: '',
      imageAsset: '',
      minutes: 15,
      servings: 2,
      tools: tools,
      diets: const [],
      meals: const [],
      ingredients: const [],
      steps: const [],
    );

    expect(recipeMeta(recipe(const [Tool.stove, Tool.rice])), '15 phút · Bếp từ');
    expect(
      recipeMeta(recipe(const [Tool.rice]), servings: true),
      '15 phút · 2 người · Nồi cơm điện',
    );
    expect(recipeMeta(recipe(const [])), '15 phút');
  });
}
