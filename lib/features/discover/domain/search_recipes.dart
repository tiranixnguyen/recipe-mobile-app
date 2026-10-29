import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/text/fold.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

List<Recipe> searchRecipes(
  List<Recipe> recipes,
  List<Ingredient> ingredients, {
  String query = '',
  int? maxMinutes,
  Tool? tool,
  Diet? diet,
  Meal? meal,
}) {
  final terms = normalizeSearch(query).split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
  final names = {for (final ingredient in ingredients) ingredient.id: ingredient.name};
  return recipes
      .where((recipe) {
        if (maxMinutes != null && recipe.minutes > maxMinutes) return false;
        if (tool != null && !recipe.tools.contains(tool)) return false;
        if (diet != null && !recipe.diets.contains(diet)) return false;
        // `meals` rỗng là món hợp mọi bữa, cùng quy ước với `suggest()`.
        if (meal != null && recipe.meals.isNotEmpty && !recipe.meals.contains(meal)) return false;
        final text = normalizeSearch(
          '${recipe.name} ${recipe.ingredients.map((i) => names[i.id] ?? '').join(' ')}',
        );
        return terms.every(text.contains);
      })
      .toList(growable: false);
}

/// Dòng tóm tắt trên kết quả: "3 món có trứng, dưới 15 phút".
String searchSummary(
  int count, {
  String query = '',
  int? maxMinutes,
  Tool? tool,
  Diet? diet,
  Meal? meal,
}) {
  final trimmed = query.trim();
  return DiscoverStrings.searchSummary(count, [
    if (trimmed.isNotEmpty) DiscoverStrings.searchHas(trimmed),
    if (maxMinutes != null) DiscoverStrings.searchUnder(maxMinutes),
    if (tool != null) DiscoverStrings.searchUses(tool.label.toLowerCase()),
    if (meal != null) DiscoverStrings.searchForMeal(meal.label.toLowerCase()),
    if (diet != null) DiscoverStrings.searchFits(diet.label.toLowerCase()),
  ]);
}
