import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/domain/availability.dart';

/// Món còn thiếu vài thứ, kèm danh sách thiếu.
typedef NearMatch = ({Recipe recipe, Availability availability});

/// Món nấu được với Tủ đồ: [ready] đủ đồ, [near] thiếu ít.
typedef PantryMatches = ({List<Recipe> ready, List<NearMatch> near});

/// Chia [recipes] theo đồ trong [pantry] (so bằng [availabilityFor]).
///
/// [ready] giữ thứ tự dữ liệu; [near] gồm món thiếu 1..[maxMissing] thứ, thiếu ít lên trước, cùng
/// số thiếu thì giữ thứ tự dữ liệu. Món thiếu nhiều hơn bị bỏ.
PantryMatches matchPantry(
  List<Recipe> recipes,
  Set<String> pantry,
  Map<String, Ingredient> ingredientsById, {
  int maxMissing = 2,
}) {
  final ready = <Recipe>[];
  final near = <NearMatch>[];
  for (final recipe in recipes) {
    final availability = availabilityFor(recipe, pantry, ingredientsById);
    final missing = availability.missing.length;
    if (missing == 0) {
      ready.add(recipe);
    } else if (missing <= maxMissing) {
      near.add((recipe: recipe, availability: availability));
    }
  }
  // List.sort không ổn định, nên so thêm vị trí ban đầu.
  final order = {for (final (i, m) in near.indexed) m.recipe.id: i};
  near.sort((a, b) {
    final byMissing = a.availability.missing.length.compareTo(b.availability.missing.length);
    return byMissing != 0 ? byMissing : order[a.recipe.id]!.compareTo(order[b.recipe.id]!);
  });
  return (ready: List.unmodifiable(ready), near: List.unmodifiable(near));
}
