import 'package:recipe_mobile_app/core/models/models.dart';

/// Tên ngày giữa câu ("Sáng thứ Năm", "Tối Chủ nhật"), theo prototype `AddToPlan`.
const _dayNames = ['thứ Hai', 'thứ Ba', 'thứ Tư', 'thứ Năm', 'thứ Sáu', 'thứ Bảy', 'Chủ nhật'];

/// Giờ mà từ đó bữa coi như đã qua, không gợi ý thêm vào nữa (nhắc bữa lúc 7h, 11h30, 18h30).
const mealEndHours = {Meal.breakfast: 10, Meal.lunch: 14, Meal.dinner: 21};

/// [count] bữa kế tiếp tính từ [now], gần nhất trước: `(ngày, bữa)` với ngày là chỉ số trong tuần
/// (0 = Thứ Hai), có thể quá 6 khi sang tuần sau.
///
/// 17h → Tối nay, Sáng mai, Trưa mai; 22h → Sáng mai, Trưa mai, Tối mai.
List<(int, Meal)> nextMeals(DateTime now, {int count = 3}) {
  final today = now.weekday - DateTime.monday;
  final slots = <(int, Meal)>[];
  for (var day = today; slots.length < count; day++) {
    for (final meal in Meal.values) {
      if (day == today && now.hour >= mealEndHours[meal]!) continue;
      if (slots.length < count) slots.add((day, meal));
    }
  }
  return slots;
}

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
