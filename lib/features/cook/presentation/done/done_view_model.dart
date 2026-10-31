import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/data/pending_cook.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';
import 'package:recipe_mobile_app/features/cook/domain/history.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

@immutable
class DoneState {
  const DoneState({
    required this.recipe,
    required this.servings,
    required this.note,
    required this.rating,
    required this.saved,
    this.finishing = false,
  });

  final Recipe recipe;
  final int servings;
  final String note;
  final CookRating? rating;
  final bool saved;
  final bool finishing;
}

/// Nấu xong một món: đánh giá, ghi chú, rồi qua PantryUpdate.
class DoneViewModel extends Notifier<AsyncValue<DoneState>> {
  DoneViewModel(this.recipeId);

  final String recipeId;

  CookRating? _rating;
  String _note = '';
  int? _servings;
  bool _finishing = false;

  @override
  AsyncValue<DoneState> build() {
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

  AsyncValue<DoneState> _done(List<Recipe> recipes, List<Ingredient> ingredients) {
    final recipe = recipes.where((r) => r.id == recipeId).firstOrNull;
    if (recipe == null) return AsyncError(RecipeNotFound(recipeId), StackTrace.current);
    final servings = _servings ??= switch (ref.read(cookSessionProvider)) {
      final s? when !s.isMeal && s.currentDish.recipeId == recipeId => s.currentDish.servings,
      _ => recipe.servings,
    };
    return AsyncData(
      DoneState(
        recipe: recipe,
        servings: servings,
        note: _note,
        rating: _rating,
        saved: ref.watch(savedIdsProvider).contains(recipeId),
        finishing: _finishing,
      ),
    );
  }

  void rate(CookRating rating) {
    _rating = _rating == rating ? null : rating;
    ref.invalidateSelf();
  }

  void setNote(String note) {
    _note = note.length > 300 ? note.substring(0, 300) : note;
    ref.invalidateSelf();
  }

  Future<void> toggleSaved() => ref.read(savedIdsProvider.notifier).toggle(recipeId);

  /// Chuẩn bị dữ liệu và lưu vào pendingCookProvider; điều hướng sang PantryUpdate ở View.
  Future<void> finish() async {
    final value = state.value;
    if (value == null || _finishing) return;
    _finishing = true;
    ref.invalidateSelf();
    try {
      final ingredients = await ref.read(ingredientsProvider.future);
      final used = usedPantryItems(
        [(recipe: value.recipe, servings: value.servings)],
        ref.read(pantryItemsProvider),
        {for (final i in ingredients) i.id: i},
      );
      final session = ref.read(cookSessionProvider);
      final now = ref.read(cookClockProvider)();
      ref
          .read(pendingCookProvider.notifier)
          .set(
            PendingCookData(
              dishes: [CookedDish(recipeId: recipeId, servings: value.servings, rating: _rating)],
              isMeal: false,
              meal: mealAt(now),
              minutes: value.recipe.minutes,
              // Một món chỉ có một ô "Ghi chú" (không chia theo món); lưu vào mealNote để
              // HistoryEntry đọc/sửa đúng chỗ.
              mealNote: _note,
              planned: session?.planned,
              usedItems: used,
            ),
          );
      await ref.read(cookSessionProvider.notifier).clear();
      ref.read(analyticsProvider).track('cook_note', {
        'dish_notes': _note.isNotEmpty ? 1 : 0,
        'meal_note': false,
      });
    } finally {
      _finishing = false;
      if (ref.mounted) ref.invalidateSelf();
    }
  }
}

final doneViewModelProvider = NotifierProvider.autoDispose
    .family<DoneViewModel, AsyncValue<DoneState>, String>(DoneViewModel.new);
