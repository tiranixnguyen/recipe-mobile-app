import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_meals.dart';

void main() {
  group('SavedMeal.tryParse', () {
    test('hợp lệ đầy đủ', () {
      final meal = SavedMeal.tryParse({
        'recipeIds': ['a', 'b'],
        'servings': 2,
        'tags': ['cheap'],
      });
      expect(meal, isNotNull);
      expect(meal!.recipeIds, ['a', 'b']);
      expect(meal.servings, 2);
      expect(meal.tags, [RecipeTag.cheap]);
    });

    test('hợp lệ không có tags', () {
      final meal = SavedMeal.tryParse({
        'recipeIds': ['a'],
        'servings': 1,
      });
      expect(meal?.tags, isEmpty);
    });

    test('tag lạ bị bỏ qua', () {
      final meal = SavedMeal.tryParse({
        'recipeIds': ['a'],
        'servings': 1,
        'tags': ['unknown_tag', 'cheap'],
      });
      expect(meal?.tags, [RecipeTag.cheap]);
    });

    test('null, không phải map, thiếu recipeIds → null', () {
      expect(SavedMeal.tryParse(null), isNull);
      expect(SavedMeal.tryParse('string'), isNull);
      expect(SavedMeal.tryParse({'servings': 1}), isNull);
    });

    test('recipeIds rỗng → null', () {
      expect(SavedMeal.tryParse({'recipeIds': [], 'servings': 1}), isNull);
    });

    test('servings không hợp lệ → null', () {
      expect(
        SavedMeal.tryParse({
          'recipeIds': ['a'],
          'servings': 0,
        }),
        isNull,
      );
    });
  });

  group('SavedMeal.toJson / round-trip', () {
    test('round-trip qua JSON', () {
      const meal = SavedMeal(
        recipeIds: ['a', 'b'],
        servings: 2,
        tags: [RecipeTag.cheap, RecipeTag.healthy],
      );
      final json = meal.toJson();
      final restored = SavedMeal.tryParse(json);
      expect(restored, meal);
    });
  });

  group('savedMealsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [localStoreProvider.overrideWith((ref) => InMemoryLocalStore())],
      );
    });

    tearDown(() => container.dispose());

    SavedMealsController notifier() => container.read(savedMealsProvider.notifier);

    test('ban đầu rỗng', () {
      expect(container.read(savedMealsProvider), isEmpty);
    });

    test('lưu bữa, mới lên đầu, bỏ lưu thì mất', () async {
      const mealA = SavedMeal(recipeIds: ['a'], servings: 1);
      const mealB = SavedMeal(recipeIds: ['b', 'c'], servings: 2, tags: [RecipeTag.cheap]);
      await notifier().saveMeal(mealA);
      await notifier().saveMeal(mealB);

      expect(container.read(savedMealsProvider), [mealB, mealA]);

      await notifier().unsaveMeal(mealA);
      expect(container.read(savedMealsProvider), [mealB]);
    });

    test('không lưu bữa trùng set món', () async {
      const meal = SavedMeal(recipeIds: ['a', 'b'], servings: 1);
      const mealDup = SavedMeal(recipeIds: ['a', 'b'], servings: 2, tags: [RecipeTag.healthy]);
      await notifier().saveMeal(meal);
      final added = await notifier().saveMeal(mealDup);
      expect(added, isFalse);
      expect(container.read(savedMealsProvider).length, 1);
    });

    test('dữ liệu tồn tại trong LocalStore', () async {
      const meal = SavedMeal(recipeIds: ['a'], servings: 1, tags: [RecipeTag.veg]);
      await notifier().saveMeal(meal);

      final raw = container.read(localStoreProvider).readString('discover.savedMeals');
      expect(raw, isNotNull);
      final parsed = jsonDecode(raw!) as List;
      expect(parsed.length, 1);
    });

    test('dựng lại từ LocalStore', () async {
      const meal = SavedMeal(recipeIds: ['a', 'b'], servings: 2, tags: [RecipeTag.cheap]);
      await notifier().saveMeal(meal);

      container.invalidate(savedMealsProvider);
      expect(container.read(savedMealsProvider), [meal]);
    });

    test('dữ liệu hỏng trong store thì bỏ qua, không crash', () async {
      final store = container.read(localStoreProvider);
      await store.writeString(
        'discover.savedMeals',
        '[{"broken": true}, {"recipeIds":["a"],"servings":1}]',
      );
      container.invalidate(savedMealsProvider);
      // bữa hỏng bị bỏ qua, chỉ còn bữa hợp lệ
      expect(container.read(savedMealsProvider).length, 1);
    });

    test('xoá dữ liệu đưa về rỗng', () async {
      await notifier().saveMeal(const SavedMeal(recipeIds: ['a'], servings: 1));
      await container.read(clearLocalDataProvider)();
      expect(container.read(savedMealsProvider), isEmpty);
    });
  });
}
