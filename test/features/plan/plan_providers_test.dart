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

    test('ngày chuẩn hoá về 0h; một bữa nhiều món, giữ thứ tự thêm', () async {
      final plan = container.read(plannedMealsProvider.notifier);
      await plan.addToPlan('trung-chien', DateTime(2026, 10, 26, 18, 30), Meal.dinner);
      await plan.addToPlan('mi-xao', DateTime(2026, 10, 26, 7), Meal.lunch);
      await plan.addToPlan('canh-ca-chua', DateTime(2026, 10, 26, 9), Meal.dinner, servings: 2);

      final day = DateTime(2026, 10, 26);
      final expected = [
        PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'trung-chien'),
        PlannedMeal(day: day, meal: Meal.lunch, recipeId: 'mi-xao'),
        PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'canh-ca-chua', servings: 2),
      ];
      expect(container.read(plannedMealsProvider), expected);
      expect(container.read(plannedMealsProvider).first.day, day);
      expect(store().readString('plan.meals'), contains('"2026-10-26"'));
      expect(store().readString('plan.meals'), contains('"servings":2'));

      container.invalidate(plannedMealsProvider);
      expect(container.read(plannedMealsProvider), expected);
    });

    test('thêm lại món đã có trong bữa chỉ đổi khẩu phần, giữ vị trí', () async {
      final plan = container.read(plannedMealsProvider.notifier);
      final day = DateTime(2026, 10, 26);
      await plan.addToPlan('a', day, Meal.dinner);
      await plan.addToPlan('b', day, Meal.dinner);
      await plan.addToPlan('a', day, Meal.lunch);
      await plan.addToPlan('a', day, Meal.dinner, servings: 3);

      expect(container.read(plannedMealsProvider), [
        PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'a', servings: 3),
        PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'b'),
        PlannedMeal(day: day, meal: Meal.lunch, recipeId: 'a'),
      ]);
    });

    test(
      'đánh dấu đã nấu các món của phiên; thêm lại món giữ đã nấu, món mới chưa nấu; dựng lại vẫn còn',
      () async {
        final plan = container.read(plannedMealsProvider.notifier);
        final day = DateTime(2026, 10, 26);
        await plan.addToPlan('a', day, Meal.dinner);
        await plan.addToPlan('b', day, Meal.dinner);
        await plan.addToPlan('a', day, Meal.lunch);
        await plan.addToPlan('d', day, Meal.dinner);
        await plan.markCooked(DateTime(2026, 10, 26, 20), Meal.dinner, ['a', 'b']);
        await plan.addToPlan('a', day, Meal.dinner, servings: 2);
        await plan.addToPlan('c', day, Meal.dinner);

        final expected = [
          PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'a', servings: 2, cooked: true),
          PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'b', cooked: true),
          PlannedMeal(day: day, meal: Meal.lunch, recipeId: 'a'),
          PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'd'),
          PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'c'),
        ];
        expect(container.read(plannedMealsProvider), expected);
        container.invalidate(plannedMealsProvider);
        expect(container.read(plannedMealsProvider), expected);
      },
    );

    test('bỏ một món giữ món còn lại; không truyền món thì bỏ cả bữa', () async {
      final plan = container.read(plannedMealsProvider.notifier);
      final day = DateTime(2026, 10, 26);
      await plan.addToPlan('a', day, Meal.lunch);
      await plan.addToPlan('b', day, Meal.lunch);
      await plan.addToPlan('c', day, Meal.lunch);
      await plan.addToPlan('a', day, Meal.dinner);

      await plan.removeFromPlan(DateTime(2026, 10, 26, 12), Meal.lunch, recipeId: 'b');
      expect(container.read(plannedMealsProvider).map((p) => (p.meal, p.recipeId)), [
        (Meal.lunch, 'a'),
        (Meal.lunch, 'c'),
        (Meal.dinner, 'a'),
      ]);

      await plan.removeFromPlan(day, Meal.lunch);
      expect(container.read(plannedMealsProvider), [
        PlannedMeal(day: day, meal: Meal.dinner, recipeId: 'a'),
      ]);
    });

    test('bản ghi cũ thiếu servings, servings 0 hoặc chuỗi thì coi là 1', () async {
      await store().writeString(
        'plan.meals',
        '[{"day": "2026-10-26", "meal": "lunch", "recipeId": "a"},'
            ' {"day": "2026-10-26", "meal": "lunch", "recipeId": "b", "servings": 0},'
            ' {"day": "2026-10-26", "meal": "lunch", "recipeId": "c", "servings": "2"},'
            ' {"day": "2026-10-26", "meal": "lunch", "recipeId": "d", "servings": 4}]',
      );
      container.invalidate(plannedMealsProvider);
      expect(container.read(plannedMealsProvider).map((p) => (p.recipeId, p.servings)), [
        ('a', 1),
        ('b', 1),
        ('c', 1),
        ('d', 4),
      ]);
    });

    test('bản ghi hỏng bị bỏ qua; xoá dữ liệu đưa về rỗng', () async {
      await store().writeString(
        'plan.meals',
        '[{"day": "2026-10-26", "meal": "brunch", "recipeId": "a"},'
            ' {"day": 20261028, "meal": "lunch", "recipeId": "c"},'
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

    test('bản ghi sai kiểu bị bỏ, giữ phần còn lại', () async {
      await store().writeString(
        'plan.shopping',
        '[{"recipeId": "a", "servings": "2"}, {"recipeId": "b", "servings": 0},'
            ' {"recipeId": "c", "servings": 2}]',
      );
      container.invalidate(shoppingProvider);
      expect(container.read(shoppingProvider), const [
        ShoppingRequest(recipeId: 'c', servings: 2),
      ]);
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
