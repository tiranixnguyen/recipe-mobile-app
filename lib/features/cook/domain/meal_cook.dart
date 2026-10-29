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

/// Phần của một món trong việc sơ chế cả bữa: món [recipeId] cần [amount] (đã nhân khẩu phần).
typedef PrepShare = ({String recipeId, double amount});

/// Một việc ở chặng "Sơ chế cả bữa", gom từ `RecipeStep.prep` của mọi món.
///
/// Việc lá ([children] rỗng) có [action] và [shares] (món nào cần bao nhiêu, theo thứ tự nấu). Việc
/// cha ([children] không rỗng) là một nguyên liệu các món sơ chế khác cách: [action] rỗng, [shares]
/// rỗng, [amount] là tổng lượng của việc con.
@immutable
class MealPrepTask {
  const MealPrepTask({
    required this.id,
    required this.ingredientId,
    required this.action,
    required this.amount,
    required this.unit,
    this.shares = const [],
    this.children = const [],
  });

  /// Khoá ổn định để lưu tick: id nguyên liệu, việc con thêm "/" và cách làm.
  final String id;
  final String ingredientId;
  final String action;
  final double amount;
  final String unit;
  final List<PrepShare> shares;
  final List<MealPrepTask> children;

  bool get isParent => children.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is MealPrepTask &&
      other.id == id &&
      other.ingredientId == ingredientId &&
      other.action == action &&
      other.amount == amount &&
      other.unit == unit &&
      listEquals(other.shares, shares) &&
      listEquals(other.children, children);

  @override
  int get hashCode => Object.hash(
    id,
    ingredientId,
    action,
    amount,
    unit,
    Object.hashAll(shares),
    Object.hashAll(children),
  );

  @override
  String toString() =>
      'MealPrepTask($id, $action, $amount $unit, $shares${isParent ? ', $children' : ''})';
}

/// Việc sơ chế cả bữa [ordered] từ `RecipeStep.prep` của các món.
///
/// - Lượng: `PrepTask.amount`, null thì cả lượng nguyên liệu của món; nhân khẩu phần bằng
///   [scaleAmount].
/// - Cùng nguyên liệu, đơn vị và cách làm thành một việc, cộng lượng, giữ phần của từng món.
/// - Cùng nguyên liệu, khác cách làm thành việc cha kèm việc con.
/// - Thứ tự: nguyên liệu gặp đầu tiên theo thứ tự nấu; trong việc cha, cách làm gặp đầu tiên.
///
/// Rỗng khi không món nào có bước sơ chế. Việc trên nguyên liệu không có trong món bị bỏ qua.
List<MealPrepTask> mealPrepTasks(List<MealDish> ordered) {
  // (nguyên liệu, đơn vị) → cách làm → món → lượng; Map giữ thứ tự gặp đầu tiên.
  final groups = <(String, String), Map<String, Map<String, double>>>{};
  for (final dish in ordered) {
    final recipe = dish.recipe;
    for (final step in recipe.steps) {
      for (final task in step.prep) {
        final ingredient = recipe.ingredients.where((i) => i.id == task.id).firstOrNull;
        if (ingredient == null) continue;
        final amount = scaleAmount(
          task.amount ?? ingredient.amount,
          recipe.servings,
          dish.servings,
        );
        final byRecipe = groups
            .putIfAbsent((task.id, ingredient.unit), () => {})
            .putIfAbsent(task.action, () => {});
        byRecipe[recipe.id] = (byRecipe[recipe.id] ?? 0) + amount;
      }
    }
  }
  final unitsPerIngredient = <String, int>{};
  for (final (id, _) in groups.keys) {
    unitsPerIngredient[id] = (unitsPerIngredient[id] ?? 0) + 1;
  }

  MealPrepTask leaf(
    String id,
    String ingredientId,
    String unit,
    String action,
    Map<String, double> byRecipe,
  ) {
    final shares = [
      for (final MapEntry(:key, :value) in byRecipe.entries) (recipeId: key, amount: value),
    ];
    return MealPrepTask(
      id: id,
      ingredientId: ingredientId,
      action: action,
      amount: shares.fold(0, (sum, s) => sum + s.amount),
      unit: unit,
      shares: List.unmodifiable(shares),
    );
  }

  MealPrepTask task(String ingredientId, String unit, Map<String, Map<String, double>> byAction) {
    // Hiếm: một nguyên liệu hai đơn vị trong bữa thì thêm đơn vị vào khoá cho khỏi trùng.
    final id = unitsPerIngredient[ingredientId]! > 1 ? '$ingredientId@$unit' : ingredientId;
    if (byAction.length == 1) {
      final MapEntry(key: action, value: byRecipe) = byAction.entries.single;
      return leaf(id, ingredientId, unit, action, byRecipe);
    }
    final children = [
      for (final MapEntry(key: action, value: byRecipe) in byAction.entries)
        leaf('$id/$action', ingredientId, unit, action, byRecipe),
    ];
    return MealPrepTask(
      id: id,
      ingredientId: ingredientId,
      action: '',
      amount: children.fold(0, (sum, c) => sum + c.amount),
      unit: unit,
      children: List.unmodifiable(children),
    );
  }

  return List.unmodifiable([
    for (final MapEntry(key: (ingredientId, unit), value: byAction) in groups.entries)
      task(ingredientId, unit, byAction),
  ]);
}

/// Khoá các việc lá của [tasks] (việc con, và việc không có con), để tính tiến độ chặng Sơ chế.
List<String> prepLeafIds(List<MealPrepTask> tasks) => List.unmodifiable([
  for (final task in tasks)
    if (task.isParent) ...task.children.map((c) => c.id) else task.id,
]);

/// Bước đứng bếp của [recipe] khi nấu cả bữa (bỏ bước sơ chế), kèm chỉ số gốc để làm khoá hẹn giờ.
List<({int index, RecipeStep step})> cookSteps(Recipe recipe) => List.unmodifiable([
  for (final (i, step) in recipe.steps.indexed)
    if (!step.isPrep) (index: i, step: step),
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
