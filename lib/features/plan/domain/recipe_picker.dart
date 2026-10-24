import 'package:recipe_mobile_app/core/models/models.dart';

/// Món để chọn cho một bữa: [saved] là món đã lưu, [all] là các món còn lại.
typedef PickerSections = ({List<Recipe> saved, List<Recipe> all});

/// Lọc [recipes] theo [query] (không phân biệt hoa thường và dấu: "trung" khớp "Trứng").
///
/// [saved] theo thứ tự [savedIds]; [all] bỏ món đã có trong [saved], món hợp [meal] (`meals` rỗng
/// hoặc có [meal]) lên trước, còn lại giữ thứ tự dữ liệu.
PickerSections pickRecipes(
  List<Recipe> recipes, {
  required List<String> savedIds,
  required Meal meal,
  String query = '',
}) {
  final needle = foldVietnamese(query.trim());
  final matching = [
    for (final r in recipes)
      if (needle.isEmpty || foldVietnamese(r.name).contains(needle)) r,
  ];
  final byId = {for (final r in matching) r.id: r};
  final saved = [for (final id in savedIds) ?byId[id]];
  final savedSet = saved.map((r) => r.id).toSet();
  bool fits(Recipe r) => r.meals.isEmpty || r.meals.contains(meal);
  final rest = matching.where((r) => !savedSet.contains(r.id));
  return (
    saved: List.unmodifiable(saved),
    all: List.unmodifiable([...rest.where(fits), ...rest.where((r) => !fits(r))]),
  );
}

const _accented = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _plain = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

/// Chữ thường, bỏ dấu tiếng Việt, để so khớp khi người dùng gõ không dấu.
String foldVietnamese(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    final i = _accented.indexOf(char);
    buffer.write(i < 0 ? char : _plain[i]);
  }
  return buffer.toString();
}
