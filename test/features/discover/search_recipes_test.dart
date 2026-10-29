import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/domain/search_recipes.dart';

const ingredients = [
  Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
  Ingredient(id: 'rice', name: 'Cơm', group: IngredientGroup.starch),
];
Recipe recipe(String id, String name, List<String> ids, {int minutes = 15}) => Recipe(
  id: id,
  name: name,
  description: '',
  imageAsset: '',
  minutes: minutes,
  servings: 1,
  tools: const [Tool.rice],
  diets: const [Diet.veg],
  meals: const [Meal.dinner],
  ingredients: [for (final id in ids) RecipeIngredient(id: id, amount: 1, unit: 'g')],
  steps: const [],
);

void main() {
  test('tìm tiếng Việt không dấu theo tên và nguyên liệu', () {
    final recipes = [
      recipe('egg', 'Trứng hấp', ['egg']),
      recipe('rice', 'Cơm nóng', ['rice']),
    ];
    expect(searchRecipes(recipes, ingredients, query: 'trung').map((r) => r.id), ['egg']);
    expect(searchRecipes(recipes, ingredients, query: 'COM').map((r) => r.id), ['rice']);
    expect(searchRecipes(recipes, ingredients, query: 'trung hap').map((r) => r.id), ['egg']);
    expect(normalizeSearch('Đậu đỏ'), 'dau do');
  });
  test('chữ dạng NFD (dấu tổ hợp) cũng bỏ dấu', () {
    // 'trứng' viết bằng u + móc (U+031B) + sắc (U+0301).
    expect(normalizeSearch('tru\u031b\u0301ng'), 'trung');
    expect(normalizeSearch('trứng'), 'trung');
    expect(normalizeSearch('Phơ\u0309'), 'pho');
  });
  test('dòng tóm tắt theo từ khoá và bộ lọc', () {
    expect(searchSummary(3), '3 món phù hợp');
    expect(searchSummary(1, query: '  trứng ', maxMinutes: 15), '1 món có trứng, dưới 15 phút');
    expect(
      searchSummary(0, tool: Tool.rice, meal: Meal.dinner, diet: Diet.veg),
      '0 món dùng nồi cơm điện, cho bữa tối, hợp ăn chay',
    );
  });
  test('kết hợp bộ lọc và từ khoá, danh sách rỗng', () {
    final recipes = [
      recipe('a', 'Cơm trứng', ['egg'], minutes: 10),
      recipe('b', 'Cơm chay', ['rice'], minutes: 30),
    ];
    expect(
      searchRecipes(
        recipes,
        ingredients,
        query: 'com',
        maxMinutes: 15,
        tool: Tool.rice,
        diet: Diet.veg,
        meal: Meal.dinner,
      ).map((r) => r.id),
      ['a'],
    );
    expect(searchRecipes(recipes, ingredients, tool: Tool.stove), isEmpty);
    expect(searchRecipes(recipes, ingredients, query: 'TRUNG').map((r) => r.id), ['a']);
    expect(searchRecipes(recipes, ingredients, maxMinutes: 10).map((r) => r.id), ['a']);
    expect(searchRecipes(recipes, ingredients, meal: Meal.breakfast), isEmpty);
    expect(searchRecipes(recipes, ingredients, diet: Diet.nospicy), isEmpty);
  });
}
