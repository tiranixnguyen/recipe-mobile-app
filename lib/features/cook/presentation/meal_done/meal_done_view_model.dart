import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';
import 'package:recipe_mobile_app/features/cook/domain/meal_cook.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

@immutable
class MealDoneState {
  const MealDoneState({
    required this.slot,
    required this.dishes,
    required this.ratings,
    required this.used,
    required this.usedUp,
    this.finishing = false,
  });

  final PlannedSlot slot;
  final List<MealDish> dishes;

  /// Đánh giá theo chỉ số món; món chưa chấm thì không có.
  final Map<int, CookRating> ratings;

  /// Đồ trong tủ cả bữa vừa dùng.
  final List<UsedItem> used;
  final Set<String> usedUp;
  final bool finishing;

  int get servings => dishes.first.servings;
  int get minutes => dishes.fold(0, (sum, d) => sum + d.recipe.minutes);

  String nameOf(String recipeId) =>
      dishes.where((d) => d.recipe.id == recipeId).firstOrNull?.recipe.name ?? recipeId;
}

/// Nấu xong cả bữa (prototype `MealCookDone`): chấm từng món, cập nhật Tủ đồ một lần, đánh dấu
/// bữa đã nấu trong Thực đơn.
class MealDoneViewModel extends Notifier<AsyncValue<MealDoneState>> {
  // Đọc phiên một lần: xong thì phiên bị xoá, màn vẫn giữ bữa vừa nấu.
  CookSession? _session;
  Map<int, CookRating> _ratings = const {};
  Set<String> _usedUp = const {};
  bool _finishing = false;

  @override
  AsyncValue<MealDoneState> build() {
    final recipes = ref.watch(recipesProvider);
    final ingredients = ref.watch(ingredientsProvider);
    return switch ((recipes, ingredients)) {
      (AsyncError(:final error, :final stackTrace), _) ||
      (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (AsyncData(value: final recipes), AsyncData(value: final ingredients)) => _done(
        recipes,
        ingredients,
      ),
      _ => const AsyncLoading(),
    };
  }

  AsyncValue<MealDoneState> _done(List<Recipe> recipes, List<Ingredient> ingredients) {
    final session = _session ??= ref.read(cookSessionProvider);
    final slot = session?.planned;
    final byId = {for (final r in recipes) r.id: r};
    if (session == null || slot == null) {
      return AsyncError(const MealNotFound(), StackTrace.current);
    }
    final dishes = [
      for (final d in session.dishes)
        if (byId[d.recipeId] case final recipe?) (recipe: recipe, servings: d.servings),
    ];
    if (dishes.isEmpty) return AsyncError(const MealNotFound(), StackTrace.current);
    return AsyncData(
      MealDoneState(
        slot: slot,
        dishes: List.unmodifiable(dishes),
        ratings: _ratings,
        used: usedPantryItems(dishes, ref.watch(pantryItemsProvider), {
          for (final i in ingredients) i.id: i,
        }),
        usedUp: _usedUp,
        finishing: _finishing,
      ),
    );
  }

  /// Chấm món thứ [dish]; chọn lại cái đang chọn thì bỏ.
  void rate(int dish, CookRating rating) {
    final next = {..._ratings};
    if (next[dish] == rating) {
      next.remove(dish);
    } else {
      next[dish] = rating;
    }
    _ratings = Map.unmodifiable(next);
    ref.invalidateSelf();
  }

  void toggleUsedUp(String ingredientId) {
    final next = {..._usedUp};
    if (!next.remove(ingredientId)) next.add(ingredientId);
    _usedUp = Set.unmodifiable(next);
    ref.invalidateSelf();
  }

  /// "Cập nhật tủ và xong": bỏ đồ đã tick khỏi tủ, ghi lịch sử từng món kèm đánh giá, đánh dấu
  /// bữa đã nấu, kết thúc phiên; có món "Ngon" thì có thể hỏi đánh giá app.
  Future<void> finish() async {
    final value = state.value;
    if (value == null || _finishing) return;
    _finishing = true;
    ref.invalidateSelf();
    try {
      final pantry = ref.read(pantryItemsProvider.notifier);
      for (final item in value.used.where((i) => value.usedUp.contains(i.ingredientId))) {
        await pantry.removeFromPantry(item.ingredientId);
      }
      final history = ref.read(cookHistoryProvider.notifier);
      final now = ref.read(cookClockProvider)();
      for (final (i, d) in value.dishes.indexed) {
        await history.record(d.recipe.id, rating: value.ratings[i], at: now);
      }
      await ref.read(plannedMealsProvider.notifier).markCooked(value.slot.day, value.slot.meal);
      await ref.read(cookSessionProvider.notifier).clear();
      if (value.ratings.containsValue(CookRating.good)) {
        await ref.read(reviewPromptProvider).maybeAsk();
      }
    } finally {
      _finishing = false;
      if (ref.mounted) ref.invalidateSelf();
    }
  }
}

final mealDoneViewModelProvider =
    NotifierProvider.autoDispose<MealDoneViewModel, AsyncValue<MealDoneState>>(
      MealDoneViewModel.new,
    );
