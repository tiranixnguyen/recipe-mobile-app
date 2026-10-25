import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/domain/plan_labels.dart';
import 'package:recipe_mobile_app/features/plan/domain/week.dart';
import 'package:recipe_mobile_app/features/plan/strings.dart';

/// Chip chọn nhanh ("Tối nay", "Trưa mai", "Tối mai").
@immutable
class QuickPick {
  const QuickPick({
    required this.label,
    required this.day,
    required this.meal,
    required this.selected,
  });

  final String label;
  final int day;
  final Meal meal;
  final bool selected;
}

@immutable
class AddToPlanState {
  const AddToPlanState({
    required this.recipe,
    required this.today,
    required this.day,
    required this.meal,
    required this.servings,
    required this.quickPicks,
    required this.daysWithMeals,
    required this.mealSummaries,
    required this.joinText,
    required this.confirmLabel,
  });

  static const minServings = 1;
  static const maxServings = 6;

  final Recipe recipe;

  /// Chỉ số trong tuần này, 0 = Thứ Hai … 6 = Chủ Nhật (như `DayStrip`).
  final int today;
  final int day;
  final Meal meal;
  final int servings;

  /// Ba bữa kế tiếp từ giờ hiện tại ("Tối nay", "Sáng mai", "Trưa mai"); bữa sang tuần sau bị
  /// ẩn vì thực đơn chỉ có tuần này.
  final List<QuickPick> quickPicks;

  /// Ngày trong tuần đã có món (chấm `herb`).
  final Set<int> daysWithMeals;

  /// Món đang có trong từng bữa của ngày đang chọn ("Cơm rang, Canh rau") hoặc "Trống".
  final Map<Meal, String> mealSummaries;

  /// "Sẽ thêm cùng … · bữa này thành n món"; null khi bữa chưa có món khác.
  final String? joinText;

  /// "Thêm vào Tối nay".
  final String confirmLabel;
}

/// Sheet "Thêm vào thực đơn" của một món (prototype `AddToPlan`).
class AddToPlanViewModel extends Notifier<AsyncValue<AddToPlanState>> {
  AddToPlanViewModel(this.recipeId);

  final String recipeId;

  @override
  AsyncValue<AddToPlanState> build() {
    final now = ref.watch(nowProvider);
    final today = weekdayIndex(now);
    final weekStart = weekStartOf(now);
    final selection = ref.watch(_selectionProvider(recipeId));
    // Bữa kế tiếp trong tuần này; tối Chủ nhật đã qua hết thì không có chip nào.
    final upcoming = [
      for (final slot in nextMeals(now))
        if (slot.$1 < 7) slot,
    ];
    final (defaultDay, defaultMeal) = upcoming.firstOrNull ?? (today, Meal.dinner);
    final day = selection.day ?? defaultDay;
    final meal = selection.meal ?? defaultMeal;
    final date = dayOfWeek(weekStart, day);
    final planned = ref.watch(plannedMealsProvider);

    return ref.watch(recipesProvider).whenData((recipes) {
      final byId = {for (final r in recipes) r.id: r};
      final recipe = byId[recipeId] ?? (throw StateError('Không có món "$recipeId"'));
      final servings = (selection.servings ?? recipe.servings).clamp(
        AddToPlanState.minServings,
        AddToPlanState.maxServings,
      );

      final daysWithMeals = <int>{
        for (final p in planned) ?indexInWeek(weekStart, p.day),
      };
      List<Recipe> dishesOf(Meal m) => [
        for (final p in planned)
          if (p.day == date && p.meal == m) ?byId[p.recipeId],
      ];

      return AddToPlanState(
        recipe: recipe,
        today: today,
        day: day,
        meal: meal,
        servings: servings,
        quickPicks: [
          for (final (d, m) in upcoming)
            QuickPick(
              label: whenLabel(m, d, today),
              day: d,
              meal: m,
              selected: d == day && m == meal,
            ),
        ],
        daysWithMeals: daysWithMeals,
        mealSummaries: {
          for (final m in Meal.values)
            m: switch (dishesOf(m)) {
              [] => PlanStrings.addEmptyMeal,
              final dishes => dishes.map((r) => r.name).join(', '),
            },
        },
        joinText: joinText(dishesOf(meal), recipeId),
        confirmLabel: PlanStrings.addConfirm(whenLabel(meal, day, today)),
      );
    });
  }

  void pickQuick(QuickPick pick) => _update((s) => s.copyWith(day: pick.day, meal: pick.meal));

  void pickDay(int day) => _update((s) => s.copyWith(day: day));

  void pickMeal(Meal meal) => _update((s) => s.copyWith(meal: meal));

  void setServings(int servings) => _update(
    (s) => s.copyWith(
      servings: servings.clamp(AddToPlanState.minServings, AddToPlanState.maxServings),
    ),
  );

  /// Thêm món vào cuối bữa đang chọn với khẩu phần đang chọn.
  Future<void> confirm() async {
    final current = state.value;
    if (current == null) return;
    final date = dayOfWeek(weekStartOf(ref.read(nowProvider)), current.day);
    await ref
        .read(plannedMealsProvider.notifier)
        .addToPlan(recipeId, date, current.meal, servings: current.servings);
  }

  void _update(_Selection Function(_Selection) change) {
    final provider = _selectionProvider(recipeId);
    ref.read(provider.notifier).set(change(ref.read(provider)));
  }
}

/// Lựa chọn trong sheet; `day`/`meal` null là bữa kế tiếp, `servings` null là khẩu phần chuẩn của
/// món.
@immutable
class _Selection {
  const _Selection({this.day, this.meal, this.servings});

  final int? day;
  final Meal? meal;
  final int? servings;

  _Selection copyWith({int? day, Meal? meal, int? servings}) => _Selection(
    day: day ?? this.day,
    meal: meal ?? this.meal,
    servings: servings ?? this.servings,
  );
}

class _SelectionNotifier extends Notifier<_Selection> {
  _SelectionNotifier(String _);

  @override
  _Selection build() => const _Selection();

  void set(_Selection selection) => state = selection;
}

final _selectionProvider = NotifierProvider.autoDispose
    .family<_SelectionNotifier, _Selection, String>(_SelectionNotifier.new);

final addToPlanViewModelProvider = NotifierProvider.autoDispose
    .family<AddToPlanViewModel, AsyncValue<AddToPlanState>, String>(AddToPlanViewModel.new);
