import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/presentation/discover/discover_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

const _ingredients = [
  Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
  Ingredient(id: 'scallion', name: 'Hành', group: IngredientGroup.spice),
  Ingredient(id: 'rice', name: 'Cơm', group: IngredientGroup.starch),
];

Recipe _recipe(String id, int minutes, List<String> needs) => Recipe(
  id: id,
  name: id,
  description: '',
  imageAsset: '',
  minutes: minutes,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: [for (final n in needs) RecipeIngredient(id: n, amount: 1, unit: 'g')],
  steps: const [],
);

void main() {
  test('nextMeal: trước 10h là sáng, trước 14h là trưa, sau đó là tối', () {
    expect(DiscoverViewModel.nextMeal(DateTime(2026, 10, 24, 7, 30)), Meal.breakfast);
    expect(DiscoverViewModel.nextMeal(DateTime(2026, 10, 24, 9, 59)), Meal.breakfast);
    expect(DiscoverViewModel.nextMeal(DateTime(2026, 10, 24, 10, 0)), Meal.lunch);
    expect(DiscoverViewModel.nextMeal(DateTime(2026, 10, 24, 13, 30)), Meal.lunch);
    expect(DiscoverViewModel.nextMeal(DateTime(2026, 10, 24, 14, 0)), Meal.dinner);
    expect(DiscoverViewModel.nextMeal(DateTime(2026, 10, 24, 18, 30)), Meal.dinner);
  });

  group('DiscoverViewModel', () {
    late ProviderContainer container;
    late ProviderSubscription<AsyncValue<DiscoverState>> sub;
    final fixedNow = DateTime(2026, 10, 24, 18, 30); // Tối

    setUp(() {
      container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
          discoverNowProvider.overrideWithValue(fixedNow),
          ingredientsProvider.overrideWith((ref) async => _ingredients),
          recipesProvider.overrideWith(
            (ref) async => [
              _recipe('trung-chien', 15, ['egg', 'scallion']),
              _recipe('canh-trung', 10, ['egg']),
              _recipe('com-rang', 20, ['rice', 'egg']),
            ],
          ),
        ],
      );
      sub = container.listen(discoverViewModelProvider, (_, _) {});
    });

    tearDown(() => container.dispose());

    Future<DiscoverState> loaded() async {
      await container.read(recipesProvider.future);
      await container.read(ingredientsProvider.future);
      return sub.read().requireValue;
    }

    test('bữa tới tính theo giờ máy và lấy danh sách món từ plannedMealsProvider', () async {
      final today = dateOnly(fixedNow);
      // Chưa có món trong thực đơn tối nay
      var state = await loaded();
      expect(state.upcomingMeal, Meal.dinner);
      expect(state.upcomingDishes, isEmpty);
      expect(state.upcomingIdeas, isNotEmpty);

      // Thêm 2 món vào bữa tối hôm nay
      await container
          .read(plannedMealsProvider.notifier)
          .addToPlan('trung-chien', today, Meal.dinner);
      await container
          .read(plannedMealsProvider.notifier)
          .addToPlan('canh-trung', today, Meal.dinner);

      state = sub.read().requireValue;
      expect(state.upcomingDishes.map((r) => r.id), ['trung-chien', 'canh-trung']);
      expect(state.upcomingTotalMinutes, 25);
    });

    test('món nấu được ngay và món thiếu phản ánh từ Tủ đồ', () async {
      var state = await loaded();
      expect(state.readyDishes, isEmpty);
      expect(state.nearDishes, isNotEmpty);

      // Thêm trứng và hành vào tủ đồ
      await container.read(pantryItemsProvider.notifier).addToPantry('egg');
      await container.read(pantryItemsProvider.notifier).addToPantry('scallion');

      state = sub.read().requireValue;
      expect(state.readyDishes.map((r) => r.id), contains('trung-chien'));
      expect(state.pantryIngredientNames, containsAll(['Trứng', 'Hành']));
    });

    test('addToShopping thêm món vào đi chợ và cập nhật addedShoppingIds', () async {
      final state = await loaded();
      final recipe = state.nearDishes.first.recipe;

      await container.read(discoverViewModelProvider.notifier).addToShopping(recipe);

      final updated = sub.read().requireValue;
      expect(updated.addedShoppingIds, contains(recipe.id));
      expect(
        container.read(shoppingProvider).map((s) => s.recipeId),
        contains(recipe.id),
      );
    });
  });
}
