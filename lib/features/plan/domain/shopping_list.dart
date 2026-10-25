import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/models/models.dart';

/// Một dòng đi chợ: tổng lượng một nguyên liệu (cùng đơn vị) cho các món cần nấu.
@immutable
class ShoppingLine {
  const ShoppingLine({
    required this.ingredientId,
    required this.unit,
    required this.amount,
    required this.recipeIds,
  });

  final String ingredientId;
  final String unit;
  final double amount;

  /// Món dùng tới nguyên liệu này, theo thứ tự gặp đầu tiên, không trùng.
  final List<String> recipeIds;

  @override
  bool operator ==(Object other) =>
      other is ShoppingLine &&
      other.ingredientId == ingredientId &&
      other.unit == unit &&
      other.amount == amount &&
      listEquals(other.recipeIds, recipeIds);

  @override
  int get hashCode => Object.hash(ingredientId, unit, amount, Object.hashAll(recipeIds));

  @override
  String toString() => 'ShoppingLine($ingredientId, $amount $unit, $recipeIds)';
}

/// Gom nguyên liệu của [dishes] (mỗi món kèm số người nấu) thành danh sách đi chợ.
///
/// Lượng nhân theo khẩu phần bằng [scaleAmount], cộng dồn theo (nguyên liệu, đơn vị); khác đơn vị
/// thì tách dòng. Giữ thứ tự xuất hiện đầu tiên. Món không có trong [recipesById] bị bỏ qua.
List<ShoppingLine> gatherShopping(
  Iterable<({String recipeId, int servings})> dishes,
  Map<String, Recipe> recipesById,
) {
  final amounts = <(String, String), double>{};
  final usedBy = <(String, String), List<String>>{};
  for (final dish in dishes) {
    final recipe = recipesById[dish.recipeId];
    if (recipe == null) continue;
    for (final ing in recipe.ingredients) {
      final key = (ing.id, ing.unit);
      final amount = scaleAmount(ing.amount, recipe.servings, dish.servings);
      amounts[key] = (amounts[key] ?? 0) + amount;
      final ids = usedBy.putIfAbsent(key, () => []);
      if (!ids.contains(recipe.id)) ids.add(recipe.id);
    }
  }
  return List.unmodifiable([
    for (final MapEntry(key: (id, unit), value: amount) in amounts.entries)
      ShoppingLine(
        ingredientId: id,
        unit: unit,
        amount: amount,
        recipeIds: List.unmodifiable(usedBy[(id, unit)]!),
      ),
  ]);
}
