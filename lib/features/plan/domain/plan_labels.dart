import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/plan/domain/week.dart';

/// Tên ngày đầu câu, 0 = Thứ Hai (prototype `MealPlan`).
const weekdayNames = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'];

/// Tên ngày ngắn trên ô ngày, 0 = Thứ Hai.
const weekdayShortNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// Tên ngày giữa câu ("Sáng thứ Năm", "Tối Chủ nhật"), theo prototype `AddToPlan`.
const _dayNames = ['thứ Hai', 'thứ Ba', 'thứ Tư', 'thứ Năm', 'thứ Sáu', 'thứ Bảy', 'Chủ nhật'];

DateTime _day(DateTime date) => addDays(date, 0);

/// Bữa tới theo giờ của [now]: trước 10h là Sáng, trước 14h là Trưa, còn lại là Tối.
Meal mealAt(DateTime now) => now.hour < 10
    ? Meal.breakfast
    : now.hour < 14
    ? Meal.lunch
    : Meal.dinner;

/// Bữa mở sẵn (tâm điểm) của ngày [date]: hôm nay là bữa tới theo giờ ([mealAt]); ngày khác là bữa
/// đầu tiên có món trong [meals], không có thì Sáng.
Meal focusMealFor(DateTime date, DateTime now, Map<Meal, List<Object>> meals) {
  if (_day(date) == _day(now)) return mealAt(now);
  return Meal.values.firstWhere((m) => meals[m]?.isNotEmpty ?? false, orElse: () => Meal.breakfast);
}

/// Tên các món: tối đa 2 tên đủ, còn lại "+N món" ("A, B +1 món").
String dishSummary(List<String> names) =>
    names.length <= 2 ? names.join(', ') : '${names.take(2).join(', ')} +${names.length - 2} món';

/// Dòng phụ của bữa thu gọn: "2 món · 40 phút · A, B"; bữa trống là "Chưa có món".
String mealSummary(List<String> names, int minutes) =>
    names.isEmpty ? 'Chưa có món' : '${names.length} món · $minutes phút · ${dishSummary(names)}';

/// Dòng phụ của bữa đang mở: "2 món · ~40 phút"; bữa trống là "Còn trống".
String mealMeta(int count, int minutes) => count == 0 ? 'Còn trống' : '$count món · ~$minutes phút';

/// "d/m", ví dụ "27/10".
String dayMonth(DateTime date) => '${date.day}/${date.month}';

/// Tiêu đề ngày đang xem: "Thứ Ba, 27/10 · Hôm nay", ngày khác thì không có "· Hôm nay".
String dayTitle(DateTime date, DateTime today) {
  final title = '${weekdayNames[weekdayIndex(date)]}, ${dayMonth(date)}';
  return _day(date) == _day(today) ? '$title · Hôm nay' : title;
}

/// Tiêu đề tuần chứa [date]: "Tuần 26/10 – 1/11".
String weekTitle(DateTime date) {
  final start = weekStartOf(date);
  return 'Tuần ${dayMonth(start)} – ${dayMonth(addDays(start, 6))}';
}

/// Ngày giữa câu nhìn từ hôm nay: "nay" hoặc tên ngày viết thường ("thứ tư", "chủ nhật"), như
/// "Bữa sáng nay", "Bữa tối thứ tư".
String dayWord(DateTime date, DateTime today) =>
    _day(date) == _day(today) ? 'nay' : weekdayNames[weekdayIndex(date)].toLowerCase();

/// Bữa [meal] của ngày [date], nhìn từ hôm nay [today]: "Tối nay", "Trưa mai", "Sáng thứ Năm",
/// "Tối Chủ nhật", "Sáng thứ Hai tuần sau" (từ ngày kia trở đi mà sang tuần sau).
String whenLabel(Meal meal, DateTime date, DateTime today) {
  final day = _day(date);
  final start = _day(today);
  final String when;
  if (day == start) {
    when = 'nay';
  } else if (day == addDays(start, 1)) {
    when = 'mai';
  } else {
    final nextWeek = weekStartOf(day).isAfter(weekStartOf(start));
    when = '${_dayNames[weekdayIndex(day)]}${nextWeek ? ' tuần sau' : ''}';
  }
  return '${meal.label} $when';
}

/// Tên đủ của ô ngày trong sheet Thêm cho trình đọc màn hình: "Thứ Ba, hôm nay", "Thứ Tư, ngày
/// mai", "Thứ Năm", "Thứ Hai tuần sau".
String dayOptionLabel(DateTime date, DateTime today) {
  final day = _day(date);
  final start = _day(today);
  final name = weekdayNames[weekdayIndex(day)];
  if (day == start) return '$name, hôm nay';
  if (day == addDays(start, 1)) return '$name, ngày mai';
  return weekStartOf(day).isAfter(weekStartOf(start)) ? '$name tuần sau' : name;
}

/// Dòng báo bữa đã có món: "Sẽ thêm cùng A, B · bữa này thành 3 món".
///
/// [existing] là món đang có trong bữa; bỏ những món nằm trong [adding] (thêm lại chỉ đổi khẩu
/// phần). Không còn món nào khác thì trả null.
String? joinText(Iterable<Recipe> existing, Iterable<String> adding) {
  final ids = adding.toSet();
  final others = [
    for (final r in existing)
      if (!ids.contains(r.id)) r.name,
  ];
  if (others.isEmpty) return null;
  return 'Sẽ thêm cùng ${dishSummary(others)} · bữa này thành ${others.length + ids.length} món';
}
