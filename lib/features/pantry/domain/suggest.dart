import 'package:recipe_mobile_app/core/models/models.dart';

/// Chọn tối đa [count] món cho [meal] từ [recipes].
///
/// Stub (PAN-00): lọc theo bữa (`meals` rỗng = mọi bữa), bỏ món trong [disliked], giữ thứ tự dữ
/// liệu. Món trong [demoted] (vừa bị chê sau khi nấu) xuống cuối, vẫn giữ thứ tự với nhau. PAN-02
/// thêm lọc dụng cụ, chế độ ăn, xếp theo đồ có sẵn; chữ ký giữ nguyên.
List<Recipe> suggest(
  List<Recipe> recipes, {
  required Meal meal,
  required int count,
  Set<String> disliked = const {},
  Set<String> demoted = const {},
}) {
  final candidates = recipes
      .where((r) => r.meals.isEmpty || r.meals.contains(meal))
      .where((r) => !disliked.contains(r.id));
  return demoteLast(candidates, demoted, (r) => r.id).take(count).toList(growable: false);
}

/// [items] giữ thứ tự, riêng phần tử có id trong [demoted] xuống cuối (cũng giữ thứ tự).
List<T> demoteLast<T>(Iterable<T> items, Set<String> demoted, String Function(T) idOf) => [
  ...items.where((e) => !demoted.contains(idOf(e))),
  ...items.where((e) => demoted.contains(idOf(e))),
];
