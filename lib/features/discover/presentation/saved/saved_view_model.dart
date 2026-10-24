import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_recipes.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

/// Món đã lưu kèm độ sẵn đồ; [availability] null khi danh mục nguyên liệu chưa tải.
typedef SavedRecipe = ({Recipe recipe, Availability? availability});

/// Món đã lưu, mới lưu lên đầu; bỏ id không còn trong dữ liệu đóng gói.
class SavedViewModel extends Notifier<AsyncValue<List<SavedRecipe>>> {
  @override
  AsyncValue<List<SavedRecipe>> build() {
    return ref.watch(recipesProvider).whenData((recipes) {
      final byId = {for (final r in recipes) r.id: r};
      return [
        for (final id in ref.watch(savedIdsProvider).toList().reversed)
          if (byId[id] case final recipe?)
            (recipe: recipe, availability: ref.watch(availabilityProvider(recipe))),
      ];
    });
  }
}

final savedViewModelProvider =
    NotifierProvider.autoDispose<SavedViewModel, AsyncValue<List<SavedRecipe>>>(
      SavedViewModel.new,
    );
