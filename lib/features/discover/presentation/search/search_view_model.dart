import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/domain/search_recipes.dart';

/// Từ khoá và bộ lọc mở sẵn từ đường dẫn (`searchLocation`).
typedef SearchFilters = ({String? query, int? maxMinutes, Tool? tool, Diet? diet, Meal? meal});

class SearchState {
  const SearchState({this.query = '', this.maxMinutes, this.tool, this.diet, this.meal});

  final String query;
  final int? maxMinutes;
  final Tool? tool;
  final Diet? diet;
  final Meal? meal;

  /// Trường nullable truyền `() => null` để xoá giá trị.
  SearchState copyWith({
    String? query,
    ValueGetter<int?>? maxMinutes,
    ValueGetter<Tool?>? tool,
    ValueGetter<Diet?>? diet,
    ValueGetter<Meal?>? meal,
  }) => SearchState(
    query: query ?? this.query,
    maxMinutes: maxMinutes == null ? this.maxMinutes : maxMinutes(),
    tool: tool == null ? this.tool : tool(),
    diet: diet == null ? this.diet : diet(),
    meal: meal == null ? this.meal : meal(),
  );

  String summary(int count) => searchSummary(
    count,
    query: query,
    maxMinutes: maxMinutes,
    tool: tool,
    diet: diet,
    meal: meal,
  );
}

class SearchViewModel extends Notifier<SearchState> {
  SearchViewModel(this.filters);

  final SearchFilters filters;

  @override
  SearchState build() => SearchState(
    query: filters.query ?? '',
    maxMinutes: filters.maxMinutes,
    tool: filters.tool,
    diet: filters.diet,
    meal: filters.meal,
  );

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleMinutes(int minutes) =>
      state = state.copyWith(maxMinutes: () => state.maxMinutes == minutes ? null : minutes);

  void toggleTool(Tool tool) =>
      state = state.copyWith(tool: () => state.tool == tool ? null : tool);

  void toggleDiet(Diet diet) =>
      state = state.copyWith(diet: () => state.diet == diet ? null : diet);

  void toggleMeal(Meal meal) =>
      state = state.copyWith(meal: () => state.meal == meal ? null : meal);

  void submit() {
    ref.read(analyticsProvider).track('search', {
      'has_query': state.query.trim().isNotEmpty,
      'filtered':
          state.maxMinutes != null ||
          state.tool != null ||
          state.diet != null ||
          state.meal != null,
    });
  }
}

final searchViewModelProvider = NotifierProvider.autoDispose
    .family<SearchViewModel, SearchState, SearchFilters>(SearchViewModel.new);

final searchResultsProvider = Provider.autoDispose.family<AsyncValue<List<Recipe>>, SearchFilters>((
  ref,
  filters,
) {
  final state = ref.watch(searchViewModelProvider(filters));
  final recipes = ref.watch(recipesProvider);
  final ingredients = ref.watch(ingredientsProvider);
  return switch ((recipes, ingredients)) {
    (AsyncError(:final error, :final stackTrace), _) ||
    (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
    (AsyncData(value: final recipes), AsyncData(value: final ingredients)) => AsyncData(
      searchRecipes(
        recipes,
        ingredients,
        query: state.query,
        maxMinutes: state.maxMinutes,
        tool: state.tool,
        diet: state.diet,
        meal: state.meal,
      ),
    ),
    _ => const AsyncLoading(),
  };
});
