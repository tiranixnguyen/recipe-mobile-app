import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/plan/domain/recipe_picker.dart';

/// Sheet chọn món cho một bữa: lọc theo từ khoá, món đã lưu (mới lưu trước) rồi tất cả món.
class RecipePickerViewModel extends Notifier<AsyncValue<PickerSections>> {
  RecipePickerViewModel(this.meal);

  final Meal meal;

  @override
  AsyncValue<PickerSections> build() {
    final query = ref.watch(_queryProvider(meal));
    final savedIds = ref.watch(savedIdsProvider).toList().reversed.toList();
    return ref
        .watch(recipesProvider)
        .whenData((recipes) => pickRecipes(recipes, savedIds: savedIds, meal: meal, query: query));
  }

  void search(String query) => ref.read(_queryProvider(meal).notifier).set(query);
}

class _Query extends Notifier<String> {
  _Query(Meal _);

  @override
  String build() => '';

  void set(String query) => state = query;
}

final _queryProvider = NotifierProvider.autoDispose.family<_Query, String, Meal>(_Query.new);

final recipePickerViewModelProvider = NotifierProvider.autoDispose
    .family<RecipePickerViewModel, AsyncValue<PickerSections>, Meal>(RecipePickerViewModel.new);
