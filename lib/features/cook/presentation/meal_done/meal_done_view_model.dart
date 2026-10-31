import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/data/pending_cook.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';
import 'package:recipe_mobile_app/features/cook/domain/meal_cook.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

@immutable
class MealDoneState {
  const MealDoneState({
    required this.slot,
    required this.dishes,
    required this.ratings,
    required this.dishNotes,
    required this.mealNote,
    this.finishing = false,
  });

  final PlannedSlot slot;
  final List<MealDish> dishes;
  final Map<int, CookRating> ratings;
  final Map<int, String> dishNotes;
  final String mealNote;
  final bool finishing;

  int get servings => dishes.first.servings;
  int get minutes => dishes.fold(0, (sum, d) => sum + d.recipe.minutes);

  String nameOf(String recipeId) =>
      dishes.where((d) => d.recipe.id == recipeId).firstOrNull?.recipe.name ?? recipeId;
}

/// Nấu xong cả bữa: chấm từng món, ghi chú, rồi qua PantryUpdate.
class MealDoneViewModel extends Notifier<AsyncValue<MealDoneState>> {
  CookSession? _session;
  Map<int, CookRating> _ratings = const {};
  Map<int, String> _dishNotes = const {};
  String _mealNote = '';
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
        dishNotes: _dishNotes,
        mealNote: _mealNote,
        finishing: _finishing,
      ),
    );
  }

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

  void setDishNote(int dish, String note) {
    final trimmed = note.length > 300 ? note.substring(0, 300) : note;
    _dishNotes = Map.unmodifiable({..._dishNotes, dish: trimmed});
    ref.invalidateSelf();
  }

  void setMealNote(String note) {
    _mealNote = note.length > 300 ? note.substring(0, 300) : note;
    ref.invalidateSelf();
  }

  /// Chuẩn bị dữ liệu, lưu vào pendingCookProvider; PantryUpdate xử lý phần còn lại.
  Future<void> finish() async {
    final value = state.value;
    if (value == null || _finishing) return;
    _finishing = true;
    ref.invalidateSelf();
    try {
      final ingredients = await ref.read(ingredientsProvider.future);
      final dishes = value.dishes;
      final used = usedPantryItems(dishes, ref.read(pantryItemsProvider), {
        for (final i in ingredients) i.id: i,
      });
      ref
          .read(pendingCookProvider.notifier)
          .set(
            PendingCookData(
              dishes: [
                for (final (i, d) in dishes.indexed)
                  CookedDish(
                    recipeId: d.recipe.id,
                    servings: d.servings,
                    rating: value.ratings[i],
                    note: value.dishNotes[i] ?? '',
                  ),
              ],
              isMeal: true,
              meal: value.slot.meal,
              minutes: value.minutes,
              mealNote: _mealNote,
              planned: value.slot,
              usedItems: used,
            ),
          );
      await ref.read(cookSessionProvider.notifier).clear();
      ref.read(analyticsProvider).track('cook_note', {
        'dish_notes': value.dishNotes.values.where((n) => n.isNotEmpty).length,
        'meal_note': _mealNote.isNotEmpty,
      });
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
