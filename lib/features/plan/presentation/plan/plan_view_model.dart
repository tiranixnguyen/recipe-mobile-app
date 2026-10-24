import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';

/// Giờ hiện tại; test override để cố định "hôm nay".
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

@immutable
class PlanState {
  const PlanState({
    required this.selectedDay,
    required this.today,
    required this.selectedDate,
    required this.meals,
    required this.daysWithMeals,
    required this.plannedCount,
  });

  /// Số bữa của một tuần (7 ngày × 3 bữa).
  static const slotsPerWeek = 21;

  /// Ngày đang xem trong tuần này, 0 = Thứ Hai … 6 = Chủ Nhật (như `DayStrip`).
  final int selectedDay;
  final int today;
  final DateTime selectedDate;

  /// Món của từng bữa ngày đang xem, theo thứ tự [Meal]; null là ô trống.
  final Map<Meal, Recipe?> meals;

  /// Ngày trong tuần đã có ít nhất một món.
  final Set<int> daysWithMeals;

  /// Số bữa đã xếp món trong tuần, trên [slotsPerWeek].
  final int plannedCount;
}

class PlanViewModel extends Notifier<AsyncValue<PlanState>> {
  @override
  AsyncValue<PlanState> build() {
    final now = ref.watch(nowProvider);
    final today = now.weekday - DateTime.monday;
    final weekStart = DateTime(now.year, now.month, now.day - today);
    final selectedDay = ref.watch(_selectedDayProvider) ?? today;
    final selectedDate = _dayOf(weekStart, selectedDay);
    final planned = ref.watch(plannedMealsProvider);

    return ref.watch(recipesProvider).whenData((recipes) {
      final byId = {for (final r in recipes) r.id: r};
      final daysWithMeals = <int>{};
      var plannedCount = 0;
      for (final p in planned) {
        final index = _indexIn(weekStart, p.day);
        if (index == null) continue;
        daysWithMeals.add(index);
        plannedCount++;
      }
      return PlanState(
        selectedDay: selectedDay,
        today: today,
        selectedDate: selectedDate,
        meals: {
          for (final meal in Meal.values)
            meal:
                byId[planned
                    .where((p) => p.day == selectedDate && p.meal == meal)
                    .firstOrNull
                    ?.recipeId],
        },
        daysWithMeals: daysWithMeals,
        plannedCount: plannedCount,
      );
    });
  }

  void selectDay(int day) => ref.read(_selectedDayProvider.notifier).select(day);

  /// Xếp [recipeId] vào bữa [meal] của ngày đang xem; ô đã có món thì thay.
  Future<void> setMeal(Meal meal, String recipeId) =>
      ref.read(plannedMealsProvider.notifier).addToPlan(recipeId, _selectedDate(), meal);

  Future<void> clearMeal(Meal meal) =>
      ref.read(plannedMealsProvider.notifier).removeFromPlan(_selectedDate(), meal);

  DateTime _selectedDate() {
    final now = ref.read(nowProvider);
    final today = now.weekday - DateTime.monday;
    return _dayOf(
      DateTime(now.year, now.month, now.day - today),
      ref.read(_selectedDayProvider) ?? today,
    );
  }

  static DateTime _dayOf(DateTime weekStart, int index) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + index);

  /// Vị trí của [day] trong tuần bắt đầu từ [weekStart], null nếu ngoài tuần.
  static int? _indexIn(DateTime weekStart, DateTime day) {
    for (var i = 0; i < 7; i++) {
      if (_dayOf(weekStart, i) == day) return i;
    }
    return null;
  }
}

/// Ngày đang xem; null là hôm nay.
class _SelectedDay extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int day) => state = day;
}

final _selectedDayProvider = NotifierProvider.autoDispose<_SelectedDay, int?>(_SelectedDay.new);

final planViewModelProvider = NotifierProvider.autoDispose<PlanViewModel, AsyncValue<PlanState>>(
  PlanViewModel.new,
);
