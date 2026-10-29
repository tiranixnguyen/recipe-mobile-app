import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/domain/availability.dart';

/// Chọn tối đa [count] món. Loại món bị chê trong 3 ngày (caller tính cửa sổ),
/// không tự gợi ý lại khi hết ứng viên. Các món còn lại so lần lượt: ít thiếu đồ,
/// đã lưu, chưa vừa nấu, đúng bữa, rồi thứ tự dữ liệu; không dùng trọng số tùy ý.
/// Hồ sơ chưa chọn dụng cụ/chế độ ăn (set rỗng) không giới hạn tương ứng.
List<Recipe> suggest(
  List<Recipe> recipes, {
  required Meal meal,
  required int count,
  Set<String> disliked = const {},
  Set<String> demoted = const {},
  Set<Tool> tools = const {},
  Set<Diet> diets = const {},
  Set<String> saved = const {},
  Set<String> recentlyCooked = const {},
  Set<String> pantry = const {},
  Map<String, Ingredient> ingredientsById = const {},
}) {
  if (count <= 0) return const [];
  final candidates = <({Recipe recipe, int position, int missing})>[];
  for (final (position, recipe) in recipes.indexed) {
    // Món không gắn bữa vẫn được xét, nhưng xếp sau món ghi rõ bữa phù hợp.
    if (!isEligible(recipe, meal: meal, tools: tools, diets: diets, disliked: disliked)) continue;
    candidates.add((
      recipe: recipe,
      position: position,
      missing: availabilityFor(recipe, pantry, ingredientsById).missing.length,
    ));
  }
  int compareBool(bool a, bool b) => (a ? 1 : 0).compareTo(b ? 1 : 0);
  candidates.sort((a, b) {
    final byMissing = a.missing.compareTo(b.missing);
    if (byMissing != 0) return byMissing;
    final bySaved = compareBool(!saved.contains(a.recipe.id), !saved.contains(b.recipe.id));
    if (bySaved != 0) return bySaved;
    final byBadRating = compareBool(
      demoted.contains(a.recipe.id),
      demoted.contains(b.recipe.id),
    );
    if (byBadRating != 0) return byBadRating;
    final byCooked = compareBool(
      recentlyCooked.contains(a.recipe.id),
      recentlyCooked.contains(b.recipe.id),
    );
    if (byCooked != 0) return byCooked;
    final byMeal = compareBool(a.recipe.meals.isEmpty, b.recipe.meals.isEmpty);
    if (byMeal != 0) return byMeal;
    return a.position.compareTo(b.position);
  });
  return List.unmodifiable(candidates.take(count).map((item) => item.recipe));
}

/// Lọc cứng dùng chung cho [suggest] và `suggestMeal`: món bị chê, dụng cụ, chế độ ăn, bữa.
///
/// Hồ sơ chưa chọn dụng cụ/chế độ ăn (set rỗng) không giới hạn tương ứng. Món không gắn bữa hợp mọi
/// bữa; [meal] null thì không lọc theo bữa.
bool isEligible(
  Recipe recipe, {
  Meal? meal,
  Set<Tool> tools = const {},
  Set<Diet> diets = const {},
  Set<String> disliked = const {},
}) {
  if (disliked.contains(recipe.id)) return false;
  if (tools.isNotEmpty && !tools.containsAll(recipe.tools)) return false;
  if (diets.isNotEmpty && !recipe.diets.toSet().containsAll(diets)) return false;
  if (meal != null && recipe.meals.isNotEmpty && !recipe.meals.contains(meal)) return false;
  return true;
}

/// [items] giữ thứ tự, riêng phần tử có id trong [demoted] xuống cuối (cũng giữ thứ tự).
List<T> demoteLast<T>(Iterable<T> items, Set<String> demoted, String Function(T) idOf) => [
  ...items.where((e) => !demoted.contains(idOf(e))),
  ...items.where((e) => demoted.contains(idOf(e))),
];

/// Lý do ngắn chỉ nêu dữ kiện kiểm chứng được; thiếu đồ không được ghi "Đủ đồ".
String suggestionReason(Recipe recipe, Availability availability) {
  final stock = availability.isReady ? 'Đủ đồ' : 'Thiếu ${availability.missing.length} thứ';
  final tool = recipe.tools.isEmpty ? '' : ', ${recipe.tools.first.shortLabel.toLowerCase()}';
  return '$stock, ${recipe.minutes} phút$tool';
}
