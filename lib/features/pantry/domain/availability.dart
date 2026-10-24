import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/models/models.dart';

/// Món nấu được ngay hay còn thiếu gì, so với đồ trong Tủ đồ.
@immutable
class Availability {
  const Availability({this.missing = const []});

  /// Tên nguyên liệu còn thiếu, viết thường, theo thứ tự trong công thức. Truyền thẳng cho
  /// `AvailabilityBadge(missing: …)`.
  final List<String> missing;

  bool get isReady => missing.isEmpty;

  @override
  bool operator ==(Object other) => other is Availability && listEquals(other.missing, missing);

  @override
  int get hashCode => Object.hashAll(missing);

  @override
  String toString() => 'Availability(missing: $missing)';
}

/// So [recipe] với [pantry] (id nguyên liệu đang có).
///
/// Bỏ qua nguyên liệu `optional` và gia vị cơ bản (`isBasicSpice`, luôn coi là có). Id không có
/// trong [ingredientsById] thì hiện bằng id để lỗi dữ liệu dễ thấy.
Availability availabilityFor(
  Recipe recipe,
  Set<String> pantry,
  Map<String, Ingredient> ingredientsById,
) {
  final missing = <String>[];
  for (final item in recipe.ingredients) {
    if (item.optional || pantry.contains(item.id)) continue;
    final ingredient = ingredientsById[item.id];
    if (ingredient != null && ingredient.isBasicSpice) continue;
    missing.add((ingredient?.name ?? item.id).toLowerCase());
  }
  return Availability(missing: List.unmodifiable(missing));
}
