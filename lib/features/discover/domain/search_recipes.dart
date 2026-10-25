import 'package:recipe_mobile_app/core/models/models.dart';

/// Chuẩn hóa tiếng Việt để truy vấn không phân biệt dấu và chữ hoa.
String normalizeSearch(String value) {
  const accented = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const plain = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final lower = value.toLowerCase();
  return lower
      .split('')
      .map((c) {
        final index = accented.indexOf(c);
        return index < 0 ? c : plain[index];
      })
      .join()
      .trim();
}

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
        if (meal != null && recipe.meals.isNotEmpty && !recipe.meals.contains(meal)) return false;
        final text = normalizeSearch(
          '${recipe.name} ${recipe.ingredients.map((i) => names[i.id] ?? '').join(' ')}',
        );
        return terms.every(text.contains);
      })
      .toList(growable: false);
}
