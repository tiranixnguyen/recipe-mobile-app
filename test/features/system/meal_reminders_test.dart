import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/system/domain/meal_reminders.dart';

void main() {
  // Thứ Hai 26/10/2026, 10:00.
  final now = DateTime(2026, 10, 26, 10);
  const lead = Duration(minutes: 30);

  ({DateTime day, Meal meal, String recipeTitle}) planned(DateTime day, Meal meal) =>
      (day: day, meal: meal, recipeTitle: 'Món ${meal.label}');

  test('nhắc trước giờ bữa một khoảng lead', () {
    final reminders = mealReminders(
      planned: [planned(DateTime(2026, 10, 26), Meal.dinner)],
      now: now,
      lead: lead,
    );

    expect(reminders, [
      (
        day: DateTime(2026, 10, 26),
        meal: Meal.dinner,
        at: DateTime(2026, 10, 26, 18),
        recipeTitle: 'Món Tối',
      ),
    ]);
  });

  test('bỏ bữa đã qua giờ nhắc, giữ bữa sau, sắp theo thời gian', () {
    final reminders = mealReminders(
      planned: [
        planned(DateTime(2026, 10, 27), Meal.breakfast),
        planned(DateTime(2026, 10, 26), Meal.lunch),
        planned(DateTime(2026, 10, 26), Meal.breakfast),
        planned(DateTime(2026, 10, 25), Meal.dinner),
      ],
      now: now,
      lead: lead,
    );

    expect(reminders.map((r) => r.at), [
      DateTime(2026, 10, 26, 11),
      DateTime(2026, 10, 27, 6, 30),
    ]);
  });

  test('giờ nhắc đúng bằng lúc này thì bỏ (đã qua)', () {
    final reminders = mealReminders(
      planned: [planned(DateTime(2026, 10, 26), Meal.lunch)],
      now: DateTime(2026, 10, 26, 11),
      lead: lead,
    );

    expect(reminders, isEmpty);
  });

  test('chỉ hẹn trong 7 ngày tới', () {
    final reminders = mealReminders(
      planned: [
        planned(DateTime(2026, 11, 2), Meal.breakfast),
        planned(DateTime(2026, 11, 3), Meal.breakfast),
      ],
      now: now,
      lead: const Duration(minutes: 60),
    );

    expect(reminders.map((r) => r.day), [DateTime(2026, 11, 2)]);
  });

  test('lead dài hơn đẩy giờ nhắc sớm hơn', () {
    final reminders = mealReminders(
      planned: [planned(DateTime(2026, 10, 26), Meal.dinner)],
      now: now,
      lead: const Duration(minutes: 60),
    );

    expect(reminders.single.at, DateTime(2026, 10, 26, 17, 30));
  });
}
