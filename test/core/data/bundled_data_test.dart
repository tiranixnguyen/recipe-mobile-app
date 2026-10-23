import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';

/// Kiểm dữ liệu thật trong `assets/data/` để CI chặn lỗi nhập liệu ngay ở PR.
void main() {
  final rawIngredients = File('assets/data/ingredients.json').readAsStringSync();
  final rawRecipes = File('assets/data/recipes.json').readAsStringSync();

  // Parse ở đây: id lạ (dụng cụ, chế độ ăn, bữa, nhóm) ném FormatException kèm id món.
  final ingredients = (jsonDecode(rawIngredients) as List)
      .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
      .toList();
  final recipes = (jsonDecode(rawRecipes) as List)
      .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
      .toList();
  final ingredientById = {for (final i in ingredients) i.id: i};

  test('id nguyên liệu không trùng', () {
    expect(_duplicates(ingredients.map((e) => e.id)), isEmpty);
  });

  test('id món không trùng', () {
    expect(_duplicates(recipes.map((e) => e.id)), isEmpty);
  });

  test('nguyên liệu nhóm gia vị phải là gia vị cơ bản (Tủ đồ không có chip gia vị)', () {
    for (final i in ingredients.where((i) => i.group == IngredientGroup.spice)) {
      expect(
        i.isBasicSpice,
        isTrue,
        reason: 'Nguyên liệu "${i.id}" nhóm spice nhưng isBasicSpice false',
      );
    }
  });

  for (final r in recipes) {
    group('Món "${r.id}"', () {
      test('nguyên liệu tham chiếu tồn tại', () {
        for (final ing in r.ingredients) {
          expect(ingredientById.keys, contains(ing.id), reason: 'Nguyên liệu "${ing.id}" không có');
        }
      });

      test('tools, ingredients, steps không rỗng', () {
        expect(r.tools, isNotEmpty, reason: 'tools rỗng');
        expect(r.ingredients, isNotEmpty, reason: 'ingredients rỗng');
        expect(r.steps, isNotEmpty, reason: 'steps rỗng');
      });

      test('servings, minutes, amount, timerSeconds dương', () {
        expect(r.servings, greaterThan(0), reason: 'servings');
        expect(r.minutes, greaterThan(0), reason: 'minutes');
        for (final ing in r.ingredients) {
          expect(ing.amount, greaterThan(0), reason: 'amount của "${ing.id}"');
        }
        for (final (i, step) in r.steps.indexed) {
          if (step.timerSeconds != null) {
            expect(step.timerSeconds, greaterThan(0), reason: 'timerSeconds bước ${i + 1}');
          }
        }
      });
    });
  }

  test('không key nào liên quan tới giá', () {
    final keys = <String>[..._keys(jsonDecode(rawIngredients)), ..._keys(jsonDecode(rawRecipes))];
    // Tách key thành từ (camelCase, snake_case) để `giaTien`, `unit_price` bị bắt còn `giai` thì không.
    final priceKeys = keys.where((k) {
      final words = k
          .replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}')
          .toLowerCase()
          .split(RegExp('[^a-z0-9]+'));
      return words.any(const {'price', 'gia', 'cost'}.contains);
    });
    expect(priceKeys, isEmpty);
  });
}

Set<String> _duplicates(Iterable<String> ids) {
  final seen = <String>{};
  return {
    for (final id in ids)
      if (!seen.add(id)) id,
  };
}

Iterable<String> _keys(Object? json) sync* {
  if (json is Map<String, dynamic>) {
    for (final entry in json.entries) {
      yield entry.key;
      yield* _keys(entry.value);
    }
  } else if (json is List) {
    for (final e in json) {
      yield* _keys(e);
    }
  }
}
