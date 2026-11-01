import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_meals.dart';
import 'package:recipe_mobile_app/features/discover/presentation/saved/saved_view_model.dart';

/// Chi tiết một bữa đã lưu, theo `SavedMeal.key`; dữ liệu là null khi bữa không còn trong Đã lưu.
class SavedMealViewModel extends Notifier<AsyncValue<SavedMealEntry?>> {
  SavedMealViewModel(this._key);

  final String _key;

  @override
  AsyncValue<SavedMealEntry?> build() {
    final meal = ref.watch(savedMealsProvider).where((m) => m.key == _key).firstOrNull;
    return ref.watch(recipesProvider).whenData((all) {
      if (meal == null) return null;
      final byId = {for (final r in all) r.id: r};
      return SavedMealEntry(meal: meal, recipes: [for (final id in meal.recipeIds) ?byId[id]]);
    });
  }

  /// Mở sheet thêm cả bữa vào thực đơn ([show], View truyền `showAddMealToPlanSheet`); ghi sự kiện
  /// khi thêm được. Lấy sẵn analytics vì sheet chuyển sang tab Thực đơn.
  Future<void> addToPlan(Future<bool> Function(List<Recipe> dishes) show) async {
    final entry = state.value;
    if (entry == null || entry.recipes.isEmpty) return;
    final analytics = ref.read(analyticsProvider);
    if (await show(entry.recipes)) {
      analytics.track('add_meal_to_plan', {'dishes': entry.recipes.length});
    }
  }

  /// Bỏ lưu bữa; null nếu bữa đã không còn.
  Future<UnsaveOutcome?> unsave() async {
    final entry = state.value;
    if (entry == null) return null;
    return unsaveEntry(ref, entry);
  }
}

final savedMealViewModelProvider = NotifierProvider.autoDispose
    .family<SavedMealViewModel, AsyncValue<SavedMealEntry?>, String>(SavedMealViewModel.new);
