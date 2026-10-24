import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [localStoreProvider.overrideWith((ref) => InMemoryLocalStore())],
    );
  });

  tearDown(() => container.dispose());

  LocalStore store() => container.read(localStoreProvider);

  group('plannedMealsProvider', () {
    test('mặc định rỗng', () {
      expect(container.read(plannedMealsProvider), isEmpty);
    });

    test('ngày chuẩn hoá về 0h; một món mỗi ô, thêm lại thì thay', () async {
      final plan = container.read(plannedMealsProvider.notifier);
      await plan.addToPlan('trung-chien', DateTime(2026, 10, 26, 18, 30), Meal.dinner);
      await plan.addToPlan('mi-xao', DateTime(2026, 10, 26, 7), Meal.lunch);
      await plan.addToPlan('canh-ca-chua', DateTime(2026, 10, 26, 9), Meal.dinner);

      final day = DateTime(2026, 10, 26);
      final expected = [
        PlannedMeal(day: day, meal: Meal.lunch, recipeId: 'mi-xao'),
        PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'canh-ca-chua'),
      ];
      expect(container.read(plannedMealsProvider), expected);
      expect(container.read(plannedMealsProvider).first.day, day);
      expect(store().readString('plan.meals'), contains('"2026-10-26"'));

      container.invalidate(plannedMealsProvider);
      expect(container.read(plannedMealsProvider), expected);
    });

    test('bỏ món khỏi ô', () async {
      final plan = container.read(plannedMealsProvider.notifier);
      await plan.addToPlan('a', DateTime(2026, 10, 26), Meal.lunch);
      await plan.removeFromPlan(DateTime(2026, 10, 26, 12), Meal.lunch);
      expect(container.read(plannedMealsProvider), isEmpty);
    });

    test('bản ghi hỏng bị bỏ qua; xoá dữ liệu đưa về rỗng', () async {
      await store().writeString(
        'plan.meals',
        '[{"day": "2026-10-26", "meal": "brunch", "recipeId": "a"},'
            ' {"day": "2026-10-27", "meal": "lunch", "recipeId": "b"}]',
      );
      container.invalidate(plannedMealsProvider);
      expect(container.read(plannedMealsProvider), [
        PlannedMeal(day: DateTime(2026, 10, 27), meal: Meal.lunch, recipeId: 'b'),
      ]);

      await container.read(clearLocalDataProvider)();
      expect(container.read(plannedMealsProvider), isEmpty);
    });
  });

  group('shoppingProvider', () {
    test('thêm món, thêm lại thì cập nhật khẩu phần, dựng lại vẫn còn', () async {
      final shopping = container.read(shoppingProvider.notifier);
      await shopping.addToShopping('a', 1);
      await shopping.addToShopping('b', 2);
      await shopping.addToShopping('a', 3);

      const expected = [
        ShoppingRequest(recipeId: 'a', servings: 3),
        ShoppingRequest(recipeId: 'b', servings: 2),
      ];
      expect(container.read(shoppingProvider), expected);

      container.invalidate(shoppingProvider);
      expect(container.read(shoppingProvider), expected);
    });

    test('JSON hỏng thì rỗng; xoá dữ liệu đưa về rỗng', () async {
      await store().writeString('plan.shopping', '[');
      container.invalidate(shoppingProvider);
      expect(container.read(shoppingProvider), isEmpty);

      await container.read(shoppingProvider.notifier).addToShopping('a', 1);
      await container.read(clearLocalDataProvider)();
      expect(container.read(shoppingProvider), isEmpty);
    });
  });
}
