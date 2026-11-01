import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/text/fold.dart';

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

/// Một dòng trên màn Đi chợ (prototype `Shopping`): nguyên liệu của thực đơn, hoặc đồ tự thêm.
@immutable
class ShoppingRow {
  const ShoppingRow({
    required this.id,
    required this.name,
    required this.uses,
    required this.group,
    this.ingredientId,
  });

  /// Khoá lưu trạng thái đã tick: `line:<nguyên liệu>:<đơn vị>` hoặc `item:<nguyên liệu hay tên>`.
  final String id;

  /// "Trứng gà · 4 quả"; đồ tự thêm thì chỉ có tên.
  final String name;

  /// Tên các món dùng tới, cách nhau dấu phẩy; null với đồ tự thêm.
  final String? uses;
  final IngredientGroup group;

  /// Null khi là tên tự gõ, không có trong danh mục (không cất vào Tủ đồ được).
  final String? ingredientId;

  @override
  bool operator ==(Object other) =>
      other is ShoppingRow &&
      other.id == id &&
      other.name == name &&
      other.uses == uses &&
      other.group == group &&
      other.ingredientId == ingredientId;

  @override
  int get hashCode => Object.hash(id, name, uses, group, ingredientId);

  @override
  String toString() => 'ShoppingRow($id, $name, $uses, ${group.id})';
}

/// Danh sách đi chợ đã gộp và trừ Tủ đồ.
typedef ShoppingSheet = ({
  /// Nhóm theo [shoppingGroupOrder], bỏ nhóm rỗng.
  List<({IngredientGroup group, List<ShoppingRow> rows})> groups,

  /// Tên (viết thường) những thứ đã có trong Tủ đồ nên không phải mua, cho dòng "Đã bỏ n thứ…".
  List<String> inPantry,
});

/// Thứ tự nhóm trên màn Đi chợ.
const shoppingGroupOrder = [
  IngredientGroup.vegetable,
  IngredientGroup.protein,
  IngredientGroup.starch,
  IngredientGroup.spice,
  IngredientGroup.other,
];

/// Ghép [lines] (thực đơn, món thêm riêng) với đồ tự thêm [items] thành danh sách đi chợ.
///
/// - Bỏ gia vị cơ bản (app coi như luôn có) và nguyên liệu không có trong [ingredientsById].
/// - Thứ đã có trong [pantry] không hiện, mà ghi vào `inPantry` (mỗi tên một lần).
/// - Đồ tự thêm trùng nguyên liệu đã có dòng từ thực đơn thì gộp vào dòng đó; tên tự gõ trùng tên
///   nguyên liệu đã có (không phân biệt dấu, hoa thường) cũng vậy. Tên tự gõ vào nhóm Khác.
ShoppingSheet buildShoppingSheet({
  required List<ShoppingLine> lines,
  required List<({String? ingredientId, String? name})> items,
  required Map<String, Ingredient> ingredientsById,
  required Map<String, Recipe> recipesById,
  required Set<String> pantry,
}) {
  final rows = <IngredientGroup, List<ShoppingRow>>{};
  final inPantry = <String>[];
  final listed = <String>{};
  final listedNames = <String>{};

  void skip(Ingredient ingredient) {
    final name = ingredient.name.toLowerCase();
    if (!inPantry.contains(name)) inPantry.add(name);
  }

  for (final line in lines) {
    final ingredient = ingredientsById[line.ingredientId];
    if (ingredient == null || ingredient.isBasicSpice) continue;
    if (pantry.contains(ingredient.id)) {
      skip(ingredient);
      continue;
    }
    listed.add(ingredient.id);
    listedNames.add(normalizeSearch(ingredient.name));
    rows
        .putIfAbsent(ingredient.group, () => [])
        .add(
          ShoppingRow(
            id: 'line:${line.ingredientId}:${line.unit}',
            name: '${ingredient.name} · ${formatAmount(line.amount)} ${line.unit}',
            uses: [
              for (final id in line.recipeIds) ?recipesById[id]?.name,
            ].join(', '),
            group: ingredient.group,
            ingredientId: ingredient.id,
          ),
        );
  }

  for (final item in items) {
    if (item.ingredientId case final id?) {
      final ingredient = ingredientsById[id];
      if (ingredient == null || listed.contains(id)) continue;
      if (pantry.contains(id)) {
        skip(ingredient);
        continue;
      }
      listed.add(id);
      listedNames.add(normalizeSearch(ingredient.name));
      rows
          .putIfAbsent(ingredient.group, () => [])
          .add(
            ShoppingRow(
              id: 'item:$id',
              name: ingredient.name,
              uses: null,
              group: ingredient.group,
              ingredientId: id,
            ),
          );
    } else if (item.name case final name? when listedNames.add(normalizeSearch(name))) {
      rows
          .putIfAbsent(IngredientGroup.other, () => [])
          .add(
            ShoppingRow(id: 'item:$name', name: name, uses: null, group: IngredientGroup.other),
          );
    }
  }

  return (
    groups: List.unmodifiable([
      for (final group in shoppingGroupOrder)
        if (rows[group] case final list? when list.isNotEmpty)
          (group: group, rows: List<ShoppingRow>.unmodifiable(list)),
    ]),
    inPantry: List.unmodifiable(inPantry),
  );
}
