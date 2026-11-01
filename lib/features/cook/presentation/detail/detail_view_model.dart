import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/domain/recipe_detail.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

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
    required this.missingIds,
    required this.allMissingInShopping,
    required this.shoppingCount,
  });

  final Recipe recipe;

  /// Đủ đồ hay thiếu gì, đưa vào `AvailabilityBadge`.
  final Availability availability;
  final List<DetailIngredient> ingredients;

  /// Gia vị cơ bản gom một dòng; rỗng thì không hiện dòng đó.
  final List<String> basicSpices;
  final List<DetailStep> steps;

  /// Nguyên liệu thiếu (bắt buộc, chưa có trong tủ) mà chưa nằm trong đi chợ: "Thêm n thứ còn
  /// thiếu vào đi chợ" sẽ thêm đúng các thứ này.
  final List<String> missingIds;

  /// Có thứ thiếu và tất cả đã nằm trong đi chợ: nút thêm thành "Đã thêm vào đi chợ" (tắt).
  final bool allMissingInShopping;

  /// Số trên badge nút Đi chợ.
  final int shoppingCount;

  /// Hiện nút thêm đồ thiếu vào đi chợ.
  bool get hasMissing => missingIds.isNotEmpty || allMissingInShopping;
}

/// Chi tiết món (prototype `Detail`). Thao tác ghi duy nhất là thêm đồ thiếu vào đi chợ: Lưu dùng
/// `SaveButton`, Thêm vào thực đơn dùng sheet của feature Thực đơn.
class DetailViewModel extends Notifier<AsyncValue<DetailState>> {
  DetailViewModel(this.recipeId);

  final String recipeId;

  /// `view_recipe` chỉ ghi một lần mỗi lần mở màn, không ghi lại khi tủ đồ đổi.
  bool _viewed = false;

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
    final shopping = ref.watch(shoppingItemsProvider);
    final shoppingIds = {for (final i in shopping) ?i.ingredientId};
    final byId = {for (final i in ingredients) i.id: i};
    final (:items, :basicSpices) = detailIngredients(recipe, pantry, byId, shoppingIds);
    final missing = [
      for (final i in items)
        if (i.status == IngredientStatus.missing) i.ingredientId,
    ];
    final inShopping = items.any((i) => i.status == IngredientStatus.inShopping);
    if (!_viewed) {
      _viewed = true;
      ref.read(analyticsProvider).track('view_recipe', {'recipe': recipe.id});
    }
    return AsyncData(
      DetailState(
        recipe: recipe,
        availability: availabilityFor(recipe, pantry, byId),
        ingredients: items,
        basicSpices: basicSpices,
        steps: List.unmodifiable([
          for (final step in recipe.steps) (text: step.text, timeLabel: stepTimeLabel(step)),
        ]),
        missingIds: List.unmodifiable(missing),
        allMissingInShopping: missing.isEmpty && inShopping,
        shoppingCount: ref.watch(shoppingCountProvider),
      ),
    );
  }

  /// "Thêm n thứ còn thiếu vào đi chợ": thêm từng thứ thiếu chưa có trong đi chợ. Trả số thứ thêm
  /// được.
  Future<int> addMissingToShopping() async {
    final ids = state.value?.missingIds ?? const [];
    final shopping = ref.read(shoppingItemsProvider.notifier);
    var added = 0;
    for (final id in ids) {
      if (await shopping.addIngredient(id) == AddToShoppingResult.added) added++;
    }
    if (added > 0) {
      ref.read(analyticsProvider).track('add_missing_to_shopping', {
        'from': 'detail',
        'items': added,
      });
    }
    return added;
  }
}

final detailViewModelProvider = NotifierProvider.autoDispose
    .family<DetailViewModel, AsyncValue<DetailState>, String>(DetailViewModel.new);
