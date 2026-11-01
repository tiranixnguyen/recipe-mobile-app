import 'package:flutter/foundation.dart';

import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/text/fold.dart';

/// Một dòng nguyên liệu gộp của cả bữa: "Hành lá · 2 nắm", kèm món dùng và trạng thái đi chợ.
@immutable
class MealIngredient {
  const MealIngredient({
    required this.ingredientId,
    required this.name,
    required this.amountText,
    required this.uses,
    this.inShopping = false,
  });

  final String ingredientId;
  final String name;

  /// Lượng cho cả bữa kèm đơn vị: "2 nắm", "1,5 muỗng canh".
  final String amountText;

  /// "Cả 3 món" khi nhiều món dùng, không thì tên món dùng.
  final String uses;

  /// Đã nằm trong danh sách đi chợ (chỉ có nghĩa với dòng còn thiếu).
  final bool inShopping;

  @override
  bool operator ==(Object other) =>
      other is MealIngredient &&
      other.ingredientId == ingredientId &&
      other.name == name &&
      other.amountText == amountText &&
      other.uses == uses &&
      other.inShopping == inShopping;

  @override
  int get hashCode => Object.hash(ingredientId, name, amountText, uses, inShopping);

  @override
  String toString() => 'MealIngredient($name · $amountText, $uses, inShopping: $inShopping)';
}

/// Nguyên liệu cả bữa chia theo Tủ đồ.
typedef MealIngredients = ({
  /// Thiếu và cần: "Còn thiếu n thứ".
  List<MealIngredient> missing,

  /// Đã có trong tủ.
  List<MealIngredient> have,

  /// Chưa có trong tủ nhưng mọi món đều ghi tuỳ chọn: không tính là thiếu.
  List<MealIngredient> optional,

  /// Gia vị cơ bản, gom một dòng ("Dầu ăn, nước mắm"); app coi như luôn có.
  List<String> basicSpices,
});

/// Gộp nguyên liệu của [recipes] cho [servings] người mỗi món.
///
/// Cộng theo (nguyên liệu, đơn vị) bằng `gatherIngredients`, giữ thứ tự xuất hiện đầu tiên. Gia vị
/// cơ bản (`Ingredient.isBasicSpice`) gom riêng. Chưa có trong [pantry]: là thiếu, trừ khi mọi món
/// dùng nó đều ghi `optional`. [shoppingIds] đánh dấu dòng thiếu đã nằm trong đi chợ. Id không có
/// trong [ingredientsById] thì hiện bằng id, như `availabilityFor`.
MealIngredients mergeMealIngredients(
  List<Recipe> recipes,
  int servings,
  Set<String> pantry,
  Map<String, Ingredient> ingredientsById,
  Set<String> shoppingIds,
) {
  final byId = {for (final r in recipes) r.id: r};
  final gathered = gatherIngredients([
    for (final r in recipes) (recipeId: r.id, servings: servings),
  ], byId);
  final required = {
    for (final r in recipes)
      for (final i in r.ingredients)
        if (!i.optional) i.id,
  };

  final missing = <MealIngredient>[];
  final have = <MealIngredient>[];
  final optional = <MealIngredient>[];
  final spices = <String>[];
  for (final g in gathered) {
    final ingredient = ingredientsById[g.ingredientId];
    final name = ingredient?.name ?? g.ingredientId;
    if (ingredient != null && ingredient.isBasicSpice) {
      if (!spices.any((s) => s.toLowerCase() == name.toLowerCase())) {
        spices.add(spices.isEmpty ? name : name.toLowerCase());
      }
      continue;
    }
    final line = MealIngredient(
      ingredientId: g.ingredientId,
      name: name,
      amountText: '${formatAmount(g.amount)} ${g.unit}',
      uses: g.recipeIds.length > 1
          ? 'Cả ${g.recipeIds.length} món'
          : byId[g.recipeIds.single]?.name ?? g.recipeIds.single,
      inShopping: shoppingIds.contains(g.ingredientId),
    );
    if (pantry.contains(g.ingredientId)) {
      have.add(line);
    } else if (required.contains(g.ingredientId)) {
      missing.add(line);
    } else {
      optional.add(line);
    }
  }
  return (
    missing: List.unmodifiable(missing),
    have: List.unmodifiable(have),
    optional: List.unmodifiable(optional),
    basicSpices: List.unmodifiable(spices),
  );
}

/// Các món chọn được trong sheet "Thêm món" / "Đổi": nhóm đã lưu trước, rồi mọi món còn lại.
typedef MealPickerLists = ({List<Recipe> saved, List<Recipe> others});

/// Lọc [all] cho sheet chọn món theo [query] (không phân biệt dấu, chữ hoa) và [role] (null là tất
/// cả). Món có id trong [savedIds] vào nhóm `saved`; mỗi nhóm xếp theo tên. Món đã có trong bữa
/// vẫn hiện (để disable), việc đó là của View.
MealPickerLists filterPickerRecipes(
  List<Recipe> all, {
  required Set<String> savedIds,
  String query = '',
  DishRole? role,
}) {
  final folded = normalizeSearch(query);
  final matches = [
    for (final r in all)
      if ((role == null || r.role == role) && normalizeSearch(r.name).contains(folded)) r,
  ]..sort((a, b) => normalizeSearch(a.name).compareTo(normalizeSearch(b.name)));
  return (
    saved: [
      for (final r in matches)
        if (savedIds.contains(r.id)) r,
    ],
    others: [
      for (final r in matches)
        if (!savedIds.contains(r.id)) r,
    ],
  );
}

/// Loại món có chip lọc trong sheet chọn món, theo thứ tự hiện; "Tất cả" là null, thêm ở View.
const pickerRoles = [DishRole.main, DishRole.soup, DishRole.side];
