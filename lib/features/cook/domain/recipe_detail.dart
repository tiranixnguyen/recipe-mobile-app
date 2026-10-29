import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';

/// Nguyên liệu so với Tủ đồ: "Có trong tủ", "Thiếu", "Tuỳ chọn".
enum IngredientStatus { inPantry, missing, optional }

/// Một dòng trong khung Nguyên liệu của Chi tiết món: "Trứng gà · 2 quả".
@immutable
class DetailIngredient {
  const DetailIngredient({required this.name, required this.amountText, required this.status});

  final String name;

  /// Lượng kèm đơn vị cho khẩu phần chuẩn của món: "2 quả", "1,5 muỗng canh".
  final String amountText;
  final IngredientStatus status;

  @override
  bool operator ==(Object other) =>
      other is DetailIngredient &&
      other.name == name &&
      other.amountText == amountText &&
      other.status == status;

  @override
  int get hashCode => Object.hash(name, amountText, status);

  @override
  String toString() => 'DetailIngredient($name · $amountText, $status)';
}

/// Chia nguyên liệu của [recipe] thành dòng có trạng thái ([items]) và gia vị cơ bản
/// ([basicSpices], gom thành một dòng "Dầu ăn, nước mắm" vì app coi như luôn có).
///
/// Nguyên liệu `optional` chưa có trong [pantry] là [IngredientStatus.optional]. Id không có trong
/// [ingredientsById] thì hiện bằng id, như `availabilityFor`.
({List<DetailIngredient> items, List<String> basicSpices}) detailIngredients(
  Recipe recipe,
  Set<String> pantry,
  Map<String, Ingredient> ingredientsById,
) {
  final items = <DetailIngredient>[];
  final spices = <String>[];
  for (final item in recipe.ingredients) {
    final ingredient = ingredientsById[item.id];
    final name = ingredient?.name ?? item.id;
    if (ingredient != null && ingredient.isBasicSpice) {
      spices.add(spices.isEmpty ? name : name.toLowerCase());
      continue;
    }
    items.add(
      DetailIngredient(
        name: name,
        amountText: '${formatAmount(item.amount)} ${item.unit}',
        status: pantry.contains(item.id)
            ? IngredientStatus.inPantry
            : item.optional
            ? IngredientStatus.optional
            : IngredientStatus.missing,
      ),
    );
  }
  return (items: List.unmodifiable(items), basicSpices: List.unmodifiable(spices));
}

/// Thời gian hẹn giờ của bước: "1 phút", "1 phút 30 giây", "45 giây"; null khi bước không hẹn giờ.
String? stepTimeLabel(RecipeStep step) {
  final seconds = step.timerSeconds;
  if (seconds == null || seconds <= 0) return null;
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return [if (minutes > 0) '$minutes phút', if (rest > 0) '$rest giây'].join(' ');
}
