import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_prep.dart';

/// Một món trong bữa đang nấu, kèm số người nấu.
typedef MealDish = ({Recipe recipe, int servings});

/// Thứ tự nấu gợi ý: món lâu (`minutes`) trước để món nhanh xong sau cùng còn nóng; bằng nhau thì giữ
/// thứ tự thêm vào bữa.
List<MealDish> suggestCookOrder(List<MealDish> dishes) {
  // List.sort không ổn định, nên so thêm vị trí ban đầu để cùng phút thì giữ thứ tự thêm.
  final indexed = dishes.indexed.toList()
    ..sort((a, b) {
      final byMinutes = b.$2.recipe.minutes.compareTo(a.$2.recipe.minutes);
      return byMinutes != 0 ? byMinutes : a.$1.compareTo(b.$1);
    });
  return List.unmodifiable(indexed.map((e) => e.$2));
}

/// Một dòng "Lấy đồ ra · cả bữa": "Trứng gà · 4 quả", kèm món dùng tới.
@immutable
class MealGatherItem {
  const MealGatherItem({
    required this.ingredientId,
    required this.name,
    required this.amountText,
    required this.recipeIds,
  });

  final String ingredientId;
  final String name;

  /// Tổng lượng kèm đơn vị theo khẩu phần từng món: "4 quả", "1,5 muỗng canh".
  final String amountText;

  /// Món dùng tới, theo thứ tự nấu, không trùng.
  final List<String> recipeIds;

  @override
  bool operator ==(Object other) =>
      other is MealGatherItem &&
      other.ingredientId == ingredientId &&
      other.name == name &&
      other.amountText == amountText &&
      listEquals(other.recipeIds, recipeIds);

  @override
  int get hashCode => Object.hash(ingredientId, name, amountText, Object.hashAll(recipeIds));

  @override
  String toString() => 'MealGatherItem($name · $amountText, $recipeIds)';
}

/// Đồ cần lấy ra cho cả bữa [ordered]: nguyên liệu trùng giữa các món cộng lượng theo khẩu phần
/// ([gatherIngredients]), khác đơn vị thì tách dòng.
///
/// Gia vị cơ bản không thành dòng riêng mà gom vào [basicSpices] ("Dầu ăn, nước mắm") như
/// `detailIngredients`. Id không có trong [ingredientsById] thì hiện bằng id.
({List<MealGatherItem> items, List<String> basicSpices}) mealGatherList(
  List<MealDish> ordered,
  Map<String, Ingredient> ingredientsById,
) {
  final gathered = gatherIngredients(
    [for (final d in ordered) (recipeId: d.recipe.id, servings: d.servings)],
    {for (final d in ordered) d.recipe.id: d.recipe},
  );
  final items = <MealGatherItem>[];
  final spiceIds = <String>{};
  final spices = <String>[];
  for (final g in gathered) {
    final ingredient = ingredientsById[g.ingredientId];
    final name = ingredient?.name ?? g.ingredientId;
    if (ingredient != null && ingredient.isBasicSpice) {
      if (spiceIds.add(g.ingredientId)) spices.add(spices.isEmpty ? name : name.toLowerCase());
      continue;
    }
    items.add(
      MealGatherItem(
        ingredientId: g.ingredientId,
        name: name,
        amountText: '${formatAmount(g.amount)} ${g.unit}',
        recipeIds: g.recipeIds,
      ),
    );
  }
  return (items: List.unmodifiable(items), basicSpices: List.unmodifiable(spices));
}

/// Đồ cần lấy ra khi chuẩn bị nấu cả bữa [ordered] ([mealGatherList]), chia theo [pantry]:
///
/// - [gather]: đồ đang có trong tủ, lượng cộng cho cả bữa.
/// - [basicSpices]: gia vị cơ bản gom một dòng.
/// - [missing]: đồ chưa có (mỗi nguyên liệu một lần), kèm ghi chú thay thế đầu tiên của nó trong
///   các món.
({List<MealGatherItem> gather, List<String> basicSpices, List<PrepMissing> missing}) mealPrepItems(
  List<MealDish> ordered,
  Set<String> pantry,
  Map<String, Ingredient> ingredientsById,
) {
  final (:items, :basicSpices) = mealGatherList(ordered, ingredientsById);
  final missingIds = <String>{};
  final missing = <PrepMissing>[];
  for (final item in items) {
    if (pantry.contains(item.ingredientId) || !missingIds.add(item.ingredientId)) continue;
    final note = [
      for (final d in ordered)
        for (final i in d.recipe.ingredients)
          if (i.id == item.ingredientId) ?i.substituteNote,
    ].firstOrNull;
    missing.add(
      PrepMissing(ingredientId: item.ingredientId, name: item.name.toLowerCase(), note: note),
    );
  }
  return (
    gather: List.unmodifiable(items.where((i) => pantry.contains(i.ingredientId))),
    basicSpices: basicSpices,
    missing: List.unmodifiable(missing),
  );
}
