import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/domain/week.dart';

/// Một món trong bữa, kèm số người nấu.
@immutable
class PlannedDish {
  const PlannedDish({required this.recipe, required this.servings});

  final Recipe recipe;
  final int servings;

  @override
  bool operator ==(Object other) =>
      other is PlannedDish && other.recipe == recipe && other.servings == servings;

  @override
  int get hashCode => Object.hash(recipe, servings);
}

@immutable
class PlanState {
  const PlanState({
    required this.selectedDay,
    required this.today,
    required this.selectedDate,
    required this.meals,
    required this.daysWithMeals,
    required this.plannedCount,
    this.cookedMeals = const {},
  });

  /// Số bữa của một tuần (7 ngày × 3 bữa).
  static const slotsPerWeek = 21;

  /// Ngày đang xem trong tuần này, 0 = Thứ Hai … 6 = Chủ Nhật (như `DayStrip`).
  final int selectedDay;
  final int today;
  final DateTime selectedDate;

  /// Món của từng bữa ngày đang xem, theo thứ tự [Meal]; mỗi bữa theo thứ tự thêm, rỗng là bữa
  /// trống. Món không còn trong dữ liệu bị bỏ.
  final Map<Meal, List<PlannedDish>> meals;

  /// Ngày trong tuần đã có ít nhất một món.
  final Set<int> daysWithMeals;

  /// Số bữa có ít nhất một món trong tuần, trên [slotsPerWeek].
  final int plannedCount;

  /// Bữa của ngày đang xem đã nấu xong cả bữa (mọi món đã nấu).
  final Set<Meal> cookedMeals;
}

class PlanViewModel extends Notifier<AsyncValue<PlanState>> {
  @override
  AsyncValue<PlanState> build() {
    final now = ref.watch(nowProvider);
    final today = weekdayIndex(now);
    final weekStart = weekStartOf(now);
    final selectedDay = ref.watch(_selectedDayProvider) ?? today;
    final selectedDate = dayOfWeek(weekStart, selectedDay);
    final planned = ref.watch(plannedMealsProvider);

    return ref.watch(recipesProvider).whenData((recipes) {
      final byId = {for (final r in recipes) r.id: r};
      final daysWithMeals = <int>{};
      final plannedSlots = <(int, Meal)>{};
      for (final p in planned) {
        final index = indexInWeek(weekStart, p.day);
        if (index == null) continue;
        daysWithMeals.add(index);
        plannedSlots.add((index, p.meal));
      }
      return PlanState(
        selectedDay: selectedDay,
        today: today,
        selectedDate: selectedDate,
        meals: {
          for (final meal in Meal.values)
            meal: List.unmodifiable([
              for (final p in planned)
                if (p.day == selectedDate && p.meal == meal)
                  if (byId[p.recipeId] case final recipe?)
                    PlannedDish(recipe: recipe, servings: p.servings),
            ]),
        },
        daysWithMeals: daysWithMeals,
        plannedCount: plannedSlots.length,
        cookedMeals: {
          for (final meal in Meal.values)
            if (planned.where((p) => p.day == selectedDate && p.meal == meal).toList()
                case final slot when slot.isNotEmpty && slot.every((p) => p.cooked))
              meal,
        },
      );
    });
  }

  void selectDay(int day) => ref.read(_selectedDayProvider.notifier).select(day);

  /// Thêm [recipeId] vào cuối bữa [meal] của ngày đang xem; món đã có thì giữ nguyên.
  Future<void> addDish(Meal meal, String recipeId) async {
    final date = _selectedDate();
    final exists = ref
        .read(plannedMealsProvider)
        .any((p) => p.day == date && p.meal == meal && p.recipeId == recipeId);
    if (exists) return;
    await ref.read(plannedMealsProvider.notifier).addToPlan(recipeId, date, meal);
  }

  /// Bỏ [recipeId] khỏi bữa [meal] của ngày đang xem, giữ các món khác.
  Future<void> removeDish(Meal meal, String recipeId) => ref
      .read(plannedMealsProvider.notifier)
      .removeFromPlan(_selectedDate(), meal, recipeId: recipeId);

  DateTime _selectedDate() {
    final now = ref.read(nowProvider);
    return dayOfWeek(weekStartOf(now), ref.read(_selectedDayProvider) ?? weekdayIndex(now));
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
