import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';

/// Một dòng trong checklist "Lấy đồ ra": "Trứng gà · 2 quả", đang có trong Tủ đồ.
@immutable
class PrepItem {
  const PrepItem({required this.ingredientId, required this.label});

  final String ingredientId;

  /// Tên kèm lượng theo khẩu phần đang chọn.
  final String label;

  @override
  bool operator ==(Object other) =>
      other is PrepItem && other.ingredientId == ingredientId && other.label == label;

  @override
  int get hashCode => Object.hash(ingredientId, label);

  @override
  String toString() => 'PrepItem($ingredientId, $label)';
}

/// Nguyên liệu chưa có trong Tủ đồ, kèm ghi chú thay thế ([RecipeIngredient.substituteNote]).
@immutable
class PrepMissing {
  const PrepMissing({required this.ingredientId, required this.name, this.note});

  final String ingredientId;

  /// Tên viết thường, đưa thẳng vào `AvailabilityBadge(missing: …)`.
  final String name;
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is PrepMissing &&
      other.ingredientId == ingredientId &&
      other.name == name &&
      other.note == note;

  @override
  int get hashCode => Object.hash(ingredientId, name, note);

  @override
  String toString() => 'PrepMissing($ingredientId, $name, $note)';
}

/// Đồ cần lấy ra khi chuẩn bị nấu [recipe] cho [servings] người.
///
/// - [gather]: nguyên liệu đang có trong [pantry], lượng nhân theo khẩu phần ([scaleIngredients]).
/// - [basicSpices]: gia vị cơ bản gom một dòng ("Dầu ăn, tiêu"), app coi như luôn có.
/// - [missing]: nguyên liệu chưa có, kể cả tuỳ chọn, theo thứ tự công thức.
///
/// Id không có trong [ingredientsById] thì hiện bằng id, như `availabilityFor`.
({List<PrepItem> gather, List<String> basicSpices, List<PrepMissing> missing}) prepItems(
  Recipe recipe,
  int servings,
  Set<String> pantry,
  Map<String, Ingredient> ingredientsById,
) {
  final gather = <PrepItem>[];
  final spices = <String>[];
  final missing = <PrepMissing>[];
  for (final item in scaleIngredients(recipe, servings)) {
    final ingredient = ingredientsById[item.id];
    final name = ingredient?.name ?? item.id;
    if (ingredient != null && ingredient.isBasicSpice) {
      spices.add(spices.isEmpty ? name : name.toLowerCase());
    } else if (pantry.contains(item.id)) {
      gather.add(
        PrepItem(
          ingredientId: item.id,
          label: '$name · ${formatAmount(item.amount)} ${item.unit}',
        ),
      );
    } else {
      missing.add(
        PrepMissing(ingredientId: item.id, name: name.toLowerCase(), note: item.substituteNote),
      );
    }
  }
  return (
    gather: List.unmodifiable(gather),
    basicSpices: List.unmodifiable(spices),
    missing: List.unmodifiable(missing),
  );
}
