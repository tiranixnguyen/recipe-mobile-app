import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/domain/recipe_detail.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

/// Id món không có trong dữ liệu đóng gói (link cũ, thông báo của món đã bỏ).
class RecipeNotFound implements Exception {
  const RecipeNotFound(this.id);

  final String id;

  @override
  String toString() => 'RecipeNotFound($id)';
}

/// Một bước trong "Cách làm", kèm "1 phút" khi bước có hẹn giờ.
typedef DetailStep = ({String text, String? timeLabel});

@immutable
class DetailState {
  const DetailState({
    required this.recipe,
    required this.availability,
    required this.ingredients,
    required this.basicSpices,
    required this.steps,
  });

  final Recipe recipe;

  /// Đủ đồ hay thiếu gì, đưa vào `AvailabilityBadge`.
  final Availability availability;
  final List<DetailIngredient> ingredients;

  /// Gia vị cơ bản gom một dòng; rỗng thì không hiện dòng đó.
  final List<String> basicSpices;
  final List<DetailStep> steps;
}

/// Chi tiết món (prototype `Detail`). Không có thao tác ghi: Lưu dùng `SaveButton`, Thêm vào thực
/// đơn dùng sheet của feature Thực đơn.
class DetailViewModel extends Notifier<AsyncValue<DetailState>> {
  DetailViewModel(this.recipeId);

  final String recipeId;

  @override
  AsyncValue<DetailState> build() {
    final recipes = ref.watch(recipesProvider);
    final ingredients = ref.watch(ingredientsProvider);
    return switch ((recipes, ingredients)) {
      (AsyncError(:final error, :final stackTrace), _) ||
      (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (AsyncData(value: final recipes), AsyncData(value: final ingredients)) => _detail(
        recipes,
        ingredients,
      ),
      _ => const AsyncLoading(),
    };
  }

  AsyncValue<DetailState> _detail(List<Recipe> recipes, List<Ingredient> ingredients) {
    final recipe = recipes.where((r) => r.id == recipeId).firstOrNull;
    if (recipe == null) return AsyncError(RecipeNotFound(recipeId), StackTrace.current);
    final pantry = ref.watch(pantryItemsProvider);
    final byId = {for (final i in ingredients) i.id: i};
    final (:items, :basicSpices) = detailIngredients(recipe, pantry, byId);
    return AsyncData(
      DetailState(
        recipe: recipe,
        availability: availabilityFor(recipe, pantry, byId),
        ingredients: items,
        basicSpices: basicSpices,
        steps: List.unmodifiable([
          for (final step in recipe.steps) (text: step.text, timeLabel: stepTimeLabel(step)),
        ]),
      ),
    );
  }
}

final detailViewModelProvider = NotifierProvider.autoDispose
    .family<DetailViewModel, AsyncValue<DetailState>, String>(DetailViewModel.new);
