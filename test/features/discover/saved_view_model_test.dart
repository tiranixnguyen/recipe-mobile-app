import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

import '../../core/fake_analytics.dart';

Recipe _recipe(String id, {int missing = 1, String? name}) => Recipe(
  id: id,
  name: name ?? id,
  description: '',
  imageAsset: '',
  minutes: 10,
  servings: 1,
  tools: const [Tool.stove],
  diets: const [],
  meals: const [],
  ingredients: [
    const RecipeIngredient(id: 'egg', amount: 1, unit: 'quả'),
    for (var i = 1; i < missing; i++) RecipeIngredient(id: 'x$i', amount: 1, unit: 'g'),
  ],
  steps: const [],
);

void main() {
  late ProviderContainer container;
  late FakeAnalytics analytics;
  late ProviderSubscription<AsyncValue<SavedState>> sub;

  setUp(() {
    analytics = FakeAnalytics();
    container = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        analyticsProvider.overrideWithValue(analytics),
        ingredientsProvider.overrideWith(
          (ref) async => const [
            Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
          ],
        ),
        recipesProvider.overrideWith(
          (ref) async => [
            _recipe('a', name: 'Món A'),
            _recipe('b', name: 'Món B'),
            _recipe('c', name: 'Món C'),
            _recipe('many', missing: 3, name: 'Thiếu nhiều'),
          ],
        ),
      ],
    );
    sub = container.listen(savedViewModelProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  SavedViewModel vm() => container.read(savedViewModelProvider.notifier);
  SavedState state() => sub.read().requireValue;

  Future<SavedState> loaded() async {
    await container.read(recipesProvider.future);
    await container.read(ingredientsProvider.future);
    return state();
  }

  Future<void> toggleRecipe(String id) => container.read(savedIdsProvider.notifier).toggle(id);

  // ---------------------------------------------------------------------------
  // Tab Món ăn
  // ---------------------------------------------------------------------------

  test('chưa lưu gì thì rỗng', () async {
    final s = await loaded();
    expect(s.recipes, isEmpty);
    expect(s.meals, isEmpty);
  });

  test('mới lưu lên đầu, bỏ lưu thì mất khỏi danh sách', () async {
    await loaded();
    await toggleRecipe('a');
    await toggleRecipe('c');
    expect(state().recipes.map((s) => s.recipe.id), ['c', 'a']);

    await toggleRecipe('c');
    expect(state().recipes.map((s) => s.recipe.id), ['a']);
  });

  test('bỏ id không còn trong dữ liệu', () async {
    await loaded();
    await toggleRecipe('gone');
    await toggleRecipe('b');
    expect(state().recipes.map((s) => s.recipe.id), ['b']);
  });

  test('kèm độ sẵn đồ, đổi theo Tủ đồ', () async {
    await loaded();
    await toggleRecipe('a');
    expect(state().recipes.single.availability!.missing, ['trứng']);

    await container.read(pantryItemsProvider.notifier).addToPantry('egg');
    expect(state().recipes.single.availability!.isReady, isTrue);
  });

  test('thiếu quá 2 thứ thì không kèm độ sẵn đồ (ẩn badge)', () async {
    await loaded();
    await toggleRecipe('many');
    expect(state().recipes.single.availability, isNull);
  });

  // ---------------------------------------------------------------------------
  // Tab Bữa ăn
  // ---------------------------------------------------------------------------

  test('lưu bữa mới lên đầu', () async {
    await loaded();
    final mealA = const SavedMeal(
      recipeIds: ['a', 'b'],
      servings: 2,
      tags: [RecipeTag.cheap],
    );
    final mealB = const SavedMeal(recipeIds: ['c'], servings: 1);
    await container.read(savedMealsProvider.notifier).saveMeal(mealA);
    await container.read(savedMealsProvider.notifier).saveMeal(mealB);

    final meals = state().meals;
    expect(meals.length, 2);
    expect(meals.first.meal.recipeIds, ['c']);
    expect(meals.first.recipes.map((r) => r.id), ['c']);
    expect(meals.first.meal.tags, isEmpty);
    expect(meals.last.meal.tags, [RecipeTag.cheap]);
  });

  test('không lưu bữa trùng (cùng set món)', () async {
    await loaded();
    final meal = const SavedMeal(recipeIds: ['a', 'b'], servings: 2);
    await container.read(savedMealsProvider.notifier).saveMeal(meal);
    await container.read(savedMealsProvider.notifier).saveMeal(meal);
    expect(state().meals.length, 1);
  });

  // ---------------------------------------------------------------------------
  // Tìm kiếm
  // ---------------------------------------------------------------------------

  test('tìm lọc theo tên món (bỏ dấu, không phân biệt hoa thường)', () async {
    await loaded();
    await toggleRecipe('a');
    await toggleRecipe('b');

    vm().setQuery('mon a');
    expect(state().filteredRecipes.map((s) => s.recipe.id), ['a']);
    expect(state().searching, isTrue);

    vm().clearQuery();
    expect(state().filteredRecipes.length, 2);
  });

  test('tìm bữa khớp tên món hoặc tag', () async {
    await loaded();
    final meal = const SavedMeal(
      recipeIds: ['a', 'b'],
      servings: 2,
      tags: [RecipeTag.cheap],
    );
    await container.read(savedMealsProvider.notifier).saveMeal(meal);

    vm().setQuery('tiet kiem');
    expect(state().filteredMeals.length, 1);

    vm().setQuery('mon a');
    expect(state().filteredMeals.length, 1);

    vm().setQuery('khong tim thay');
    expect(state().filteredMeals, isEmpty);
  });

  // ---------------------------------------------------------------------------
  // Bỏ lưu + hoàn tác
  // ---------------------------------------------------------------------------

  test('unsaveRecipe bỏ khỏi danh sách, ghi analytics', () async {
    await loaded();
    await toggleRecipe('a');

    final outcome = await vm().unsaveRecipe(state().recipes.single.recipe);
    expect(outcome.kind, UnsaveKind.recipe);
    expect(outcome.name, 'Món A');
    expect(state().recipes, isEmpty);
    expect(analytics.events.last, 'unsave');
    expect(analytics.params.last, {'kind': 'recipe', 'undo': false});
  });

  test('undo khôi phục món và ghi analytics undo:true', () async {
    await loaded();
    await toggleRecipe('a');
    final r = state().recipes.single.recipe;
    final outcome = await vm().unsaveRecipe(r);
    await vm().undo(outcome);

    expect(state().recipes.single.recipe.id, 'a');
    expect(analytics.params.last, {'kind': 'recipe', 'undo': true});
  });

  test('unsaveMeal bỏ khỏi danh sách, ghi analytics', () async {
    await loaded();
    final meal = const SavedMeal(recipeIds: ['a'], servings: 1);
    await container.read(savedMealsProvider.notifier).saveMeal(meal);

    final item = state().meals.single;
    final outcome = await vm().unsaveMeal(item);
    expect(outcome.kind, UnsaveKind.meal);
    expect(state().meals, isEmpty);
    expect(analytics.params.last, {'kind': 'meal', 'undo': false});
  });

  test('undo bữa khôi phục lại', () async {
    await loaded();
    final meal = const SavedMeal(recipeIds: ['a'], servings: 1);
    await container.read(savedMealsProvider.notifier).saveMeal(meal);

    final item = state().meals.single;
    final outcome = await vm().unsaveMeal(item);
    await vm().undo(outcome);

    expect(state().meals.single.meal.recipeIds, ['a']);
    expect(analytics.params.last, {'kind': 'meal', 'undo': true});
  });

  // ---------------------------------------------------------------------------
  // Lỗi tải dữ liệu
  // ---------------------------------------------------------------------------

  test('dữ liệu lỗi thì state lỗi', () async {
    final failing = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWith((ref) => InMemoryLocalStore()),
        ingredientsProvider.overrideWith(
          (ref) async => const [
            Ingredient(id: 'egg', name: 'Trứng', group: IngredientGroup.protein),
          ],
        ),
        recipesProvider.overrideWith(
          (ref) => Future<List<Recipe>>.error(const FormatException('hỏng')),
        ),
      ],
    );
    addTearDown(failing.dispose);
    final failSub = failing.listen(savedViewModelProvider, (_, _) {});
    await expectLater(failing.read(recipesProvider.future), throwsFormatException);
    expect(failSub.read().hasError, isTrue);
  });
}
