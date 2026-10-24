import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/plan/domain/recipe_picker.dart';

Recipe _recipe(String id, String name, {List<Meal> meals = const []}) => Recipe(
  id: id,
  name: name,
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: meals,
  ingredients: const [],
  steps: const [],
);

void main() {
  final recipes = [
    _recipe('banh-mi', 'Bánh mì trứng ốp', meals: [Meal.breakfast]),
    _recipe('canh', 'Canh cà chua trứng', meals: [Meal.lunch, Meal.dinner]),
    _recipe('mi', 'Mì xào rau cải', meals: [Meal.dinner]),
    _recipe('khoai', 'Khoai lang vi sóng'),
  ];

  test('món đã lưu theo thứ tự truyền vào, phần còn lại món hợp bữa lên trước', () {
    final sections = pickRecipes(recipes, savedIds: ['mi', 'gone', 'banh-mi'], meal: Meal.lunch);

    expect(sections.saved.map((r) => r.id), ['mi', 'banh-mi']);
    expect(sections.all.map((r) => r.id), ['canh', 'khoai']);
  });

  test('tìm không phân biệt hoa thường và dấu', () {
    final sections = pickRecipes(recipes, savedIds: ['canh'], meal: Meal.dinner, query: ' TRUNG ');

    expect(sections.saved.map((r) => r.id), ['canh']);
    expect(sections.all.map((r) => r.id), ['banh-mi']);
  });

  test('không khớp gì thì cả hai rỗng', () {
    final sections = pickRecipes(recipes, savedIds: const [], meal: Meal.dinner, query: 'phở');
    expect(sections.saved, isEmpty);
    expect(sections.all, isEmpty);
  });

  test('foldVietnamese bỏ dấu và đ', () {
    expect(foldVietnamese('Đậu phụ sốt cà chua'), 'dau phu sot ca chua');
    expect(foldVietnamese('Khoai lang VI SÓNG'), 'khoai lang vi song');
  });
}
