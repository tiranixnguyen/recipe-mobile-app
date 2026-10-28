import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/domain/search_recipes.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.maxMinutes,
    this.tool,
    this.diet,
    this.meal,
  });

  final String query;
  final int? maxMinutes;
  final Tool? tool;
  final Diet? diet;
  final Meal? meal;

  String summary(int count) {
    final parts = <String>[
      if (query.trim().isNotEmpty) 'có ${query.trim()}',
      if (maxMinutes != null) 'dưới $maxMinutes phút',
      if (tool != null) 'dùng ${tool!.label.toLowerCase()}',
      if (meal != null) 'cho bữa ${meal!.label.toLowerCase()}',
      if (diet != null) 'hợp ${diet!.label.toLowerCase()}',
    ];
    return '$count món${parts.isEmpty ? ' phù hợp' : ' ${parts.join(', ')}'}';
  }
}

class SearchViewModel extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void initialize({String? query, int? maxMinutes, Tool? tool, Diet? diet, Meal? meal}) {
    state = SearchState(
      query: query ?? '',
      maxMinutes: maxMinutes,
      tool: tool,
      diet: diet,
      meal: meal,
    );
  }

  void setQuery(String query) => state = SearchState(
    query: query,
    maxMinutes: state.maxMinutes,
    tool: state.tool,
    diet: state.diet,
    meal: state.meal,
  );

  void toggleMinutes(int minutes) => initialize(
    query: state.query,
    maxMinutes: state.maxMinutes == minutes ? null : minutes,
    tool: state.tool,
    diet: state.diet,
    meal: state.meal,
  );

  void toggleTool(Tool tool) => initialize(
    query: state.query,
    maxMinutes: state.maxMinutes,
    tool: state.tool == tool ? null : tool,
    diet: state.diet,
    meal: state.meal,
  );

  void toggleDiet(Diet diet) => initialize(
    query: state.query,
    maxMinutes: state.maxMinutes,
    tool: state.tool,
    diet: state.diet == diet ? null : diet,
    meal: state.meal,
  );

  void toggleMeal(Meal meal) => initialize(
    query: state.query,
    maxMinutes: state.maxMinutes,
    tool: state.tool,
    diet: state.diet,
    meal: state.meal == meal ? null : meal,
  );

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

final searchViewModelProvider = NotifierProvider.autoDispose<SearchViewModel, SearchState>(
  SearchViewModel.new,
);

final searchResultsProvider = Provider.autoDispose<AsyncValue<List<Recipe>>>((ref) {
  final state = ref.watch(searchViewModelProvider);
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
