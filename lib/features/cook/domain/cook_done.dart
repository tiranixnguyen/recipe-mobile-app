import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';

/// Một dòng "Cập nhật Tủ đồ" sau khi nấu: đồ trong tủ vừa dùng, "Đã dùng 2 quả".
@immutable
class UsedItem {
  const UsedItem({
    required this.ingredientId,
    required this.name,
    required this.note,
    this.recipeIds = const [],
  });

  final String ingredientId;
  final String name;
  final String note;

  /// Món dùng tới, theo thứ tự món.
  final List<String> recipeIds;

  @override
  bool operator ==(Object other) =>
      other is UsedItem &&
      other.ingredientId == ingredientId &&
      other.name == name &&
      other.note == note &&
      listEquals(other.recipeIds, recipeIds);

  @override
  int get hashCode => Object.hash(ingredientId, name, note, Object.hashAll(recipeIds));

  @override
  String toString() => 'UsedItem($ingredientId, $name, $note)';
}

/// Đồ trong [pantry] mà [dishes] (món kèm số người nấu) vừa dùng, để hỏi đã hết chưa.
///
/// Bỏ gia vị cơ bản (không nằm trong tủ). Nguyên liệu trùng giữa các món cộng lượng
/// ([gatherIngredients]); cùng nguyên liệu khác đơn vị thì ghép "Đã dùng 2 quả, 100 g". Id không có
/// trong [ingredientsById] thì hiện bằng id.
List<UsedItem> usedPantryItems(
  List<({Recipe recipe, int servings})> dishes,
  Set<String> pantry,
  Map<String, Ingredient> ingredientsById,
) {
  final gathered = gatherIngredients(
    [for (final d in dishes) (recipeId: d.recipe.id, servings: d.servings)],
    {for (final d in dishes) d.recipe.id: d.recipe},
  );
  final amounts = <String, List<String>>{};
  final usedBy = <String, Set<String>>{};
  for (final g in gathered) {
    if (!pantry.contains(g.ingredientId)) continue;
    if (ingredientsById[g.ingredientId]?.isBasicSpice ?? false) continue;
    amounts.putIfAbsent(g.ingredientId, () => []).add('${formatAmount(g.amount)} ${g.unit}');
    usedBy.putIfAbsent(g.ingredientId, () => {}).addAll(g.recipeIds);
  }
  final order = [for (final d in dishes) d.recipe.id];
  return List.unmodifiable([
    for (final MapEntry(key: id, value: used) in amounts.entries)
      UsedItem(
        ingredientId: id,
        name: ingredientsById[id]?.name ?? id,
        note: 'Đã dùng ${used.join(', ')}',
        recipeIds: List.unmodifiable(order.where(usedBy[id]!.contains)),
      ),
  ]);
}
