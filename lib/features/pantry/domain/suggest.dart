import 'package:recipe_mobile_app/core/models/models.dart';

/// Chọn tối đa [count] món cho [meal] từ [recipes].
///
/// Stub (PAN-00): lọc theo bữa (`meals` rỗng = mọi bữa), bỏ món trong [disliked], giữ thứ tự dữ
/// liệu. PAN-02 thêm lọc dụng cụ, chế độ ăn, xếp theo đồ có sẵn; chữ ký giữ nguyên.
List<Recipe> suggest(
  List<Recipe> recipes, {
  required Meal meal,
  required int count,
  Set<String> disliked = const {},
}) {
  return recipes
      .where((r) => r.meals.isEmpty || r.meals.contains(meal))
      .where((r) => !disliked.contains(r.id))
      .take(count)
      .toList(growable: false);
}
