import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';

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

/// Một việc trong bước "Sơ chế cả bữa": bước `prep` [stepIndex] (chỉ số gốc) của món [recipeId].
@immutable
class MealPrepTask {
  const MealPrepTask({required this.recipeId, required this.stepIndex, required this.text});

  final String recipeId;
  final int stepIndex;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is MealPrepTask &&
      other.recipeId == recipeId &&
      other.stepIndex == stepIndex &&
      other.text == text;

  @override
  int get hashCode => Object.hash(recipeId, stepIndex, text);

  @override
  String toString() => 'MealPrepTask($recipeId#$stepIndex, $text)';
}

/// Việc sơ chế cả bữa: các bước `prep` theo thứ tự nấu [ordered], trong món giữ thứ tự bước.
///
/// Rỗng khi không món nào có bước sơ chế — khi đó bỏ bước "Sơ chế cả bữa".
List<MealPrepTask> mealPrepTasks(List<MealDish> ordered) => List.unmodifiable([
  for (final dish in ordered)
    for (final (i, step) in dish.recipe.steps.indexed)
      if (step.prep) MealPrepTask(recipeId: dish.recipe.id, stepIndex: i, text: step.text),
]);

/// Bước đứng bếp của [recipe] khi nấu cả bữa (bỏ bước `prep`), kèm chỉ số gốc để làm khoá hẹn giờ.
List<({int index, RecipeStep step})> cookSteps(Recipe recipe) => List.unmodifiable([
  for (final (i, step) in recipe.steps.indexed)
    if (!step.prep) (index: i, step: step),
]);

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
