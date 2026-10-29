import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/text/fold.dart';

/// Trạng thái một chip nguyên liệu trong Tủ đồ.
enum ChipStatus {
  /// Chưa có, chưa định mua.
  none,

  /// Đang có trong tủ (dấu tích).
  have,

  /// Đang nằm trong danh sách đi chợ (icon giỏ).
  needed,
}

/// Trạng thái chip của [ingredientId]; đang có trong tủ thì thắng đang cần mua.
ChipStatus chipStatus(
  String ingredientId, {
  required Set<String> have,
  required Set<String> needed,
}) {
  if (have.contains(ingredientId)) return ChipStatus.have;
  if (needed.contains(ingredientId)) return ChipStatus.needed;
  return ChipStatus.none;
}

/// Bộ lọc dưới ô tìm: Tất cả / Đang có / Cần mua.
enum PantryFilter { all, have, needed }

/// Nhóm hiển thị trong Tủ đồ, theo thứ tự prototype `Pantry`. Gia vị và Khác gộp một nhóm.
enum PantryGroupKey {
  starch('Tinh bột'),
  protein('Đạm'),
  vegetable('Rau củ'),
  other('Gia vị & khác');

  const PantryGroupKey(this.label);

  final String label;

  static PantryGroupKey of(IngredientGroup group) => switch (group) {
    IngredientGroup.starch => starch,
    IngredientGroup.protein => protein,
    IngredientGroup.vegetable => vegetable,
    IngredientGroup.spice || IngredientGroup.other => other,
  };
}

/// Một nhóm đã lọc: [items] là chip được hiện; [haveCount], [neededCount] đếm trên cả nhóm, không
/// phụ thuộc từ khoá hay bộ lọc.
typedef PantryGroupView = ({
  PantryGroupKey key,
  List<Ingredient> items,
  int haveCount,
  int neededCount,
});

/// Số đang có và đang cần mua.
typedef PantryCounts = ({int have, int needed});

/// Nguyên liệu hiện trong Tủ đồ, gom theo [PantryGroupKey] và lọc theo [query], [filter].
///
/// Bỏ gia vị cơ bản (luôn coi là có). [query] bỏ dấu, không phân biệt hoa thường, khớp tên nguyên
/// liệu hoặc tên nhóm; khớp tên nhóm ("tinh bot") thì hiện cả nhóm, vẫn theo [filter]. Nhóm không còn
/// chip nào bị bỏ. [needed] là id nguyên liệu trong danh sách đi chợ.
List<PantryGroupView> filterPantry(
  List<Ingredient> ingredients, {
  String query = '',
  PantryFilter filter = PantryFilter.all,
  required Set<String> have,
  required Set<String> needed,
}) {
  final q = normalizeSearch(query);
  final groups = _group(ingredients);
  return [
    for (final MapEntry(:key, value: items) in groups.entries)
      if (_filterGroup(key, items, q, filter, have, needed) case final shown when shown.isNotEmpty)
        (
          key: key,
          items: shown,
          haveCount: items.where((i) => _status(i, have, needed) == ChipStatus.have).length,
          neededCount: items.where((i) => _status(i, have, needed) == ChipStatus.needed).length,
        ),
  ];
}

/// Số trên bộ lọc "Đang có (n)" / "Cần mua (n)", chỉ đếm nguyên liệu có chip trong Tủ đồ.
PantryCounts filterCounts(
  List<Ingredient> ingredients, {
  required Set<String> have,
  required Set<String> needed,
}) {
  var haveCount = 0;
  var neededCount = 0;
  for (final ingredient in ingredients.where((i) => !i.isBasicSpice)) {
    switch (_status(ingredient, have, needed)) {
      case ChipStatus.have:
        haveCount++;
      case ChipStatus.needed:
        neededCount++;
      case ChipStatus.none:
    }
  }
  return (have: haveCount, needed: neededCount);
}

/// Số cho dòng "Có n thứ · m thứ đang cần mua" ở header: như [filterCounts], cần mua cộng thêm
/// [customCount] tên người dùng tự gõ vào đi chợ.
PantryCounts pantrySummary(
  List<Ingredient> ingredients, {
  required Set<String> have,
  required Set<String> needed,
  int customCount = 0,
}) {
  final counts = filterCounts(ingredients, have: have, needed: needed);
  return (have: counts.have, needed: counts.needed + customCount);
}

Map<PantryGroupKey, List<Ingredient>> _group(List<Ingredient> ingredients) {
  final groups = {for (final key in PantryGroupKey.values) key: <Ingredient>[]};
  for (final ingredient in ingredients.where((i) => !i.isBasicSpice)) {
    groups[PantryGroupKey.of(ingredient.group)]!.add(ingredient);
  }
  return groups;
}

List<Ingredient> _filterGroup(
  PantryGroupKey key,
  List<Ingredient> items,
  String q,
  PantryFilter filter,
  Set<String> have,
  Set<String> needed,
) {
  final groupHit = q.isNotEmpty && normalizeSearch(key.label).contains(q);
  return items
      .where((ingredient) {
        final status = _status(ingredient, have, needed);
        if (filter == PantryFilter.have && status != ChipStatus.have) return false;
        if (filter == PantryFilter.needed && status != ChipStatus.needed) return false;
        return q.isEmpty || groupHit || normalizeSearch(ingredient.name).contains(q);
      })
      .toList(growable: false);
}

ChipStatus _status(Ingredient ingredient, Set<String> have, Set<String> needed) =>
    chipStatus(ingredient.id, have: have, needed: needed);
