import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/text/fold.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_meals.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_recipes.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

/// Mẹo "nhấn giữ rồi kéo vào thùng rác" ở Đã lưu; ẩn hẳn khi lần đầu bỏ lưu bằng kéo thả.
const savedDragTip = 'saved.dragToTrash';

/// Món đã lưu kèm độ sẵn đồ để hiện `AvailabilityBadge`; null khi thiếu quá [_maxMissing].
typedef SavedRecipeItem = ({Recipe recipe, Availability? availability});

/// Bữa đã lưu kèm danh sách Recipe đầy đủ (để hiện MealMosaic và tên).
typedef SavedMealItem = ({SavedMeal meal, List<Recipe> recipes});

@immutable
class SavedState {
  const SavedState({
    required this.query,
    required this.recipes,
    required this.meals,
    required this.filteredRecipes,
    required this.filteredMeals,
  });

  final String query;

  /// Tất cả món đã lưu (chưa lọc).
  final List<SavedRecipeItem> recipes;

  /// Tất cả bữa đã lưu (chưa lọc).
  final List<SavedMealItem> meals;

  /// Món sau khi lọc theo [query].
  final List<SavedRecipeItem> filteredRecipes;

  /// Bữa sau khi lọc theo [query] (khớp tên món hoặc tag).
  final List<SavedMealItem> filteredMeals;

  bool get searching => query.trim().isNotEmpty;
}

enum UnsaveKind { recipe, meal }

typedef UnsaveOutcome = ({UnsaveKind kind, String name, Object item});

class SavedViewModel extends Notifier<AsyncValue<SavedState>> {
  /// Badge chỉ hiện khi đủ đồ hoặc thiếu ít.
  static const _maxMissing = 2;

  @override
  AsyncValue<SavedState> build() {
    final query = ref.watch(_queryProvider);
    final savedIds = ref.watch(savedIdsProvider);
    final savedMeals = ref.watch(savedMealsProvider);

    return ref.watch(recipesProvider).whenData((allRecipes) {
      final byId = {for (final r in allRecipes) r.id: r};

      final recipes = [
        for (final id in savedIds.toList().reversed)
          if (byId[id] case final recipe?)
            (
              recipe: recipe,
              availability: _badgeWorthy(ref.watch(availabilityProvider(recipe))),
            ),
      ];

      final meals = [
        for (final meal in savedMeals)
          (
            meal: meal,
            recipes: [for (final id in meal.recipeIds) ?byId[id]],
          ),
      ];

      final q = normalizeSearch(query);
      return SavedState(
        query: query,
        recipes: recipes,
        meals: meals,
        filteredRecipes: q.isEmpty ? recipes : _filterRecipes(recipes, q),
        filteredMeals: q.isEmpty ? meals : _filterMeals(meals, q),
      );
    });
  }

  void setQuery(String query) => ref.read(_queryProvider.notifier).set(query);

  void clearQuery() => ref.read(_queryProvider.notifier).set('');

  /// Bỏ lưu món; trả [UnsaveOutcome] để View báo snackbar và Hoàn tác.
  Future<UnsaveOutcome> unsaveRecipe(Recipe recipe) async {
    await ref.read(savedIdsProvider.notifier).unsave(recipe.id);
    ref.read(analyticsProvider).track('unsave', {'kind': 'recipe', 'undo': false});
    return (kind: UnsaveKind.recipe, name: recipe.name, item: recipe);
  }

  /// Bỏ lưu bữa; trả [UnsaveOutcome] để View báo snackbar và Hoàn tác.
  Future<UnsaveOutcome> unsaveMeal(SavedMealItem item) async {
    await ref.read(savedMealsProvider.notifier).unsaveMeal(item.meal);
    ref.read(analyticsProvider).track('unsave', {'kind': 'meal', 'undo': false});
    final name = _mealName(item.recipes);
    return (kind: UnsaveKind.meal, name: name, item: item.meal);
  }

  /// Hoàn tác bỏ lưu món/bữa.
  Future<void> undo(UnsaveOutcome outcome) async {
    if (outcome.kind == UnsaveKind.recipe && outcome.item is Recipe) {
      final recipe = outcome.item as Recipe;
      await ref.read(savedIdsProvider.notifier).save(recipe.id);
      ref.read(analyticsProvider).track('unsave', {'kind': 'recipe', 'undo': true});
    } else if (outcome.kind == UnsaveKind.meal && outcome.item is SavedMeal) {
      final meal = outcome.item as SavedMeal;
      await ref.read(savedMealsProvider.notifier).saveMeal(meal);
      ref.read(analyticsProvider).track('unsave', {'kind': 'meal', 'undo': true});
    }
  }
}

final savedViewModelProvider = NotifierProvider.autoDispose<SavedViewModel, AsyncValue<SavedState>>(
  SavedViewModel.new,
);

/// Query dùng riêng trong màn Đã lưu; tách ra để không mất khi data đổi.
class _QueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final _queryProvider = NotifierProvider.autoDispose<_QueryController, String>(_QueryController.new);

Availability? _badgeWorthy(Availability? availability) =>
    availability != null && availability.missing.length <= SavedViewModel._maxMissing
    ? availability
    : null;

List<SavedRecipeItem> _filterRecipes(List<SavedRecipeItem> items, String q) => [
  for (final item in items)
    if (normalizeSearch(item.recipe.name).contains(q)) item,
];

List<SavedMealItem> _filterMeals(List<SavedMealItem> items, String q) => [
  for (final item in items)
    if (_mealMatches(item, q)) item,
];

bool _mealMatches(SavedMealItem item, String q) {
  for (final r in item.recipes) {
    if (normalizeSearch(r.name).contains(q)) return true;
  }
  for (final tag in item.meal.tags) {
    if (normalizeSearch(tag.label).contains(q)) return true;
  }
  return false;
}

/// "A + B + 3 món" — tên bữa hiển thị.
String _mealName(List<Recipe> recipes) => switch (recipes.length) {
  0 => 'Bữa ăn',
  1 => recipes[0].name,
  2 => '${recipes[0].name} + ${recipes[1].name}',
  final n => '${recipes[0].name} + ${recipes[1].name} +${n - 2} món',
};

/// Tên hiển thị bữa từ [SavedMealItem].
String mealDisplayName(SavedMealItem item) => _mealName(item.recipes);
