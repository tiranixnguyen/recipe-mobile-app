import 'package:recipe_mobile_app/core/models/models.dart';

/// Giờ của từng bữa dùng để nhắc, theo nếp sinh viên ký túc xá.
const mealTimes = <Meal, ({int hour, int minute})>{
  Meal.breakfast: (hour: 7, minute: 0),
  Meal.lunch: (hour: 11, minute: 30),
  Meal.dinner: (hour: 18, minute: 30),
};

/// Chỉ hẹn trước chừng này ngày; lịch được tính lại mỗi khi mở app hoặc đổi thực đơn.
const mealReminderHorizon = Duration(days: 7);

/// Một lời nhắc bữa cần hẹn: bữa [Meal] của ngày `day` (0h), hiện lúc `at`.
typedef MealReminder = ({DateTime day, Meal meal, DateTime at, String recipeTitle});

/// Lời nhắc cho các bữa đã lên trong [planned]: lúc [mealTimes] trừ [lead], chỉ những lúc còn ở
/// tương lai (sau [now]) và trong [mealReminderHorizon]. Sắp theo thời gian.
List<MealReminder> mealReminders({
  required Iterable<({DateTime day, Meal meal, String recipeTitle})> planned,
  required DateTime now,
  required Duration lead,
}) {
  final until = now.add(mealReminderHorizon);
  final reminders = <MealReminder>[];
  for (final p in planned) {
    final time = mealTimes[p.meal]!;
    final day = DateTime(p.day.year, p.day.month, p.day.day);
    final at = DateTime(day.year, day.month, day.day, time.hour, time.minute).subtract(lead);
    if (at.isAfter(now) && !at.isAfter(until)) {
      reminders.add((day: day, meal: p.meal, at: at, recipeTitle: p.recipeTitle));
    }
  }
  return reminders..sort((a, b) => a.at.compareTo(b.at));
}
