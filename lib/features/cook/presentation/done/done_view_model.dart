import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

@immutable
class DoneState {
  const DoneState({
    required this.recipe,
    required this.servings,
    required this.used,
    required this.usedUp,
    required this.rating,
    required this.saved,
    this.finishing = false,
  });

  final Recipe recipe;
  final int servings;

  /// Đồ trong tủ vừa dùng; rỗng thì không có khung "Cập nhật Tủ đồ".
  final List<UsedItem> used;

  /// Id đồ đã tick "Hết", mặc định không tick.
  final Set<String> usedUp;
  final CookRating? rating;
  final bool saved;

  /// Đang lưu sau khi bấm "Cập nhật tủ và xong": khoá nút để không ghi lịch sử hai lần.
  final bool finishing;
}

/// Nấu xong một món (prototype `CookDone`): bỏ đồ đã hết khỏi tủ, đánh giá, lưu món.
class DoneViewModel extends Notifier<AsyncValue<DoneState>> {
  DoneViewModel(this.recipeId);

  final String recipeId;

  // Giữ qua các lần build lại, chỉ mất khi rời màn.
  Set<String> _usedUp = const {};
  CookRating? _rating;
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
    // Đọc một lần: xong thì phiên bị xoá, màn vẫn giữ khẩu phần đã nấu.
    final servings = _servings ??= switch (ref.read(cookSessionProvider)) {
      final s? when !s.isMeal && s.currentDish.recipeId == recipeId => s.currentDish.servings,
      _ => recipe.servings,
    };
    final used = usedPantryItems(
      [(recipe: recipe, servings: servings)],
      ref.watch(pantryItemsProvider),
      {for (final i in ingredients) i.id: i},
    );
    return AsyncData(
      DoneState(
        recipe: recipe,
        servings: servings,
        used: used,
        usedUp: _usedUp,
        rating: _rating,
        saved: ref.watch(savedIdsProvider).contains(recipeId),
        finishing: _finishing,
      ),
    );
  }

  /// Tick / bỏ tick "Hết" của đồ [ingredientId].
  void toggleUsedUp(String ingredientId) {
    final next = {..._usedUp};
    if (!next.remove(ingredientId)) next.add(ingredientId);
    _usedUp = Set.unmodifiable(next);
    ref.invalidateSelf();
  }

  /// Chọn đánh giá; chọn lại cái đang chọn thì bỏ.
  void rate(CookRating rating) {
    _rating = _rating == rating ? null : rating;
    ref.invalidateSelf();
  }

  Future<void> toggleSaved() => ref.read(savedIdsProvider.notifier).toggle(recipeId);

  /// "Cập nhật tủ và xong": bỏ đồ đã tick khỏi tủ, ghi lịch sử nấu kèm đánh giá, kết thúc phiên
  /// nấu; đủ lần "Ngon" thì hỏi đánh giá app.
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
      await ref
          .read(cookHistoryProvider.notifier)
          .record(recipeId, rating: value.rating, at: ref.read(cookClockProvider)());
      await ref.read(cookSessionProvider.notifier).clear();
      final analytics = ref.read(analyticsProvider);
      analytics.track('finish_cooking', {
        'used_up': value.usedUp.length,
        'rated': value.rating != null,
        'meal_dishes': 1,
      });
      if (value.rating case final rating?) {
        analytics.track('rate_recipe', {'rating': rating.id});
      }
      if (value.rating == CookRating.good) await ref.read(reviewPromptProvider).maybeAsk();
    } finally {
      _finishing = false;
      if (ref.mounted) ref.invalidateSelf();
    }
  }
}

final doneViewModelProvider = NotifierProvider.autoDispose
    .family<DoneViewModel, AsyncValue<DoneState>, String>(DoneViewModel.new);
