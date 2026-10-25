import 'package:recipe_mobile_app/core/models/models.dart';

/// Tên ngày giữa câu ("Sáng thứ Năm", "Tối Chủ nhật"), theo prototype `AddToPlan`.
const _dayNames = ['thứ Hai', 'thứ Ba', 'thứ Tư', 'thứ Năm', 'thứ Sáu', 'thứ Bảy', 'Chủ nhật'];

/// Bữa [meal] của ngày [day] trong tuần, nhìn từ hôm nay [today] (chỉ số 0 = Thứ Hai … 6 = CN):
/// "Tối nay", "Trưa mai", "Sáng thứ Năm", "Tối Chủ nhật".
String whenLabel(Meal meal, int day, int today) {
  final when = day == today
      ? 'nay'
      : day == today + 1
      ? 'mai'
      : _dayNames[day];
  return '${meal.label} $when';
}

/// Dòng báo bữa đã có món: "Sẽ thêm cùng A, B · bữa này thành 3 món".
///
/// [existing] là món đang có trong bữa; bỏ chính món [recipeId] đang thêm nếu nó đã có (thêm lại
/// chỉ đổi khẩu phần). Không còn món nào khác thì trả null.
String? joinText(Iterable<Recipe> existing, String recipeId) {
  final others = [
    for (final r in existing)
      if (r.id != recipeId) r.name,
  ];
  if (others.isEmpty) return null;
  return 'Sẽ thêm cùng ${others.join(', ')} · bữa này thành ${others.length + 1} món';
}
