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
/// Cách gom xem [gatherIngredients]: nhân theo khẩu phần, cộng dồn theo (nguyên liệu, đơn vị), giữ thứ
/// tự xuất hiện đầu tiên, bỏ món không có trong [recipesById].
List<ShoppingLine> gatherShopping(
  Iterable<({String recipeId, int servings})> dishes,
  Map<String, Recipe> recipesById,
) {
  return List.unmodifiable([
    for (final g in gatherIngredients(dishes, recipesById))
      ShoppingLine(
        ingredientId: g.ingredientId,
        unit: g.unit,
        amount: g.amount,
        recipeIds: g.recipeIds,
      ),
  ]);
}
