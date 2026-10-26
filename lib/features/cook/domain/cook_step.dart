import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';

/// Một dòng trong sheet Nguyên liệu khi đang nấu: "Trứng gà" — "2 quả".
typedef StepIngredient = ({String name, String amountText});

/// Nguyên liệu của [recipe] cho [servings] người, cho sheet Nguyên liệu ở màn Từng bước.
///
/// Mọi nguyên liệu (kể cả tuỳ chọn) một dòng, lượng theo [scaleIngredients]; gia vị cơ bản gom vào
/// [basicSpices] ("Dầu ăn, tiêu", hiện "Vừa đủ"). Id không có trong [ingredientsById] thì hiện bằng
/// id.
({List<StepIngredient> items, List<String> basicSpices}) stepIngredients(
  Recipe recipe,
  int servings,
  Map<String, Ingredient> ingredientsById,
) {
  final items = <StepIngredient>[];
  final spices = <String>[];
  for (final item in scaleIngredients(recipe, servings)) {
    final ingredient = ingredientsById[item.id];
    final name = ingredient?.name ?? item.id;
    if (ingredient != null && ingredient.isBasicSpice) {
      spices.add(spices.isEmpty ? name : name.toLowerCase());
    } else {
      items.add((name: name, amountText: '${formatAmount(item.amount)} ${item.unit}'));
    }
  }
  return (items: List.unmodifiable(items), basicSpices: List.unmodifiable(spices));
}

/// Key hẹn báo hết giờ (`NotificationService.scheduleTimer`) của bước [step] món thứ [dish] trong
/// phiên nấu: mỗi món tối đa [maxStepsPerDish] bước.
int cookTimerKey(int dish, int step) => dish * maxStepsPerDish + step;

const maxStepsPerDish = 50;
