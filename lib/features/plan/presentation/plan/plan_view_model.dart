import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/data/planned_meals.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_items.dart';
import 'package:recipe_mobile_app/features/plan/domain/plan_labels.dart';
import 'package:recipe_mobile_app/features/plan/domain/week.dart';

/// Chế độ xem của Thực đơn: một ngày (bữa tâm điểm) hoặc cả tuần (#48).
enum PlanMode { day, week }

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

/// Món vừa bỏ khỏi bữa, giữ lại để Hoàn tác đúng vị trí.
typedef RemovedDish = ({PlannedMeal entry, int index});

@immutable
class PlanState {
  const PlanState({
    required this.selectedDate,
    required this.today,
    required this.isToday,
    required this.mode,
    required this.focusMeal,
    required this.meals,
    required this.cookedMeals,
    required this.title,
    required this.dayWord,
    required this.summaries,
    required this.metas,
    required this.shoppingCount,
  });

  /// Ngày đang xem (0h), bất kỳ ngày nào.
  final DateTime selectedDate;

  /// Hôm nay (0h).
  final DateTime today;
  final bool isToday;
  final PlanMode mode;

  /// Bữa đang mở trong accordion: người dùng chọn, mặc định [focusMealFor].
  final Meal focusMeal;

  /// Món của từng bữa ngày đang xem, theo thứ tự [Meal]; mỗi bữa theo thứ tự thêm, rỗng là bữa
  /// trống. Món không còn trong dữ liệu bị bỏ.
  final Map<Meal, List<PlannedDish>> meals;

  /// Bữa của ngày đang xem đã nấu xong cả bữa (mọi món đã nấu).
  final Set<Meal> cookedMeals;

  /// "Thứ Ba, 27/10 · Hôm nay" (Ngày) hoặc "Tuần 26/10 – 1/11" (Tuần).
  final String title;

  /// "nay" hoặc "thứ tư", ghép vào "Bữa sáng nay còn trống".
  final String dayWord;

  /// Dòng phụ bữa thu gọn ("2 món · 40 phút · A, B").
  final Map<Meal, String> summaries;

  /// Dòng phụ bữa đang mở ("2 món · ~40 phút").
  final Map<Meal, String> metas;

  /// Số trên badge nút Đi chợ.
  final int shoppingCount;

  bool get dayEmpty => meals.values.every((dishes) => dishes.isEmpty);
}

class PlanViewModel extends Notifier<AsyncValue<PlanState>> {
  @override
  AsyncValue<PlanState> build() {
    final now = ref.watch(nowProvider);
    final today = dateOnly(now);
    final selection = ref.watch(_selectionProvider);
    final date = selection.date ?? today;
    final planned = ref.watch(plannedMealsProvider);
    final shoppingCount = ref.watch(shoppingCountProvider);

    return ref.watch(recipesProvider).whenData((recipes) {
      final byId = {for (final r in recipes) r.id: r};
      final meals = {
        for (final meal in Meal.values)
          meal: List<PlannedDish>.unmodifiable([
            for (final p in planned)
              if (p.day == date && p.meal == meal)
                if (byId[p.recipeId] case final recipe?)
                  PlannedDish(recipe: recipe, servings: p.servings),
          ]),
      };
      int minutesOf(Meal meal) => meals[meal]!.fold(0, (sum, d) => sum + d.recipe.minutes);
      return PlanState(
        selectedDate: date,
        today: today,
        isToday: date == today,
        mode: selection.mode,
        focusMeal: selection.focus[date] ?? focusMealFor(date, now, meals),
        meals: meals,
        cookedMeals: {
          for (final meal in Meal.values)
            if (planned.where((p) => p.day == date && p.meal == meal).toList() case final slot
                when slot.isNotEmpty && slot.every((p) => p.cooked))
              meal,
        },
        title: selection.mode == PlanMode.week ? weekTitle(date) : dayTitle(date, today),
        dayWord: dayWord(date, today),
        summaries: {
          for (final meal in Meal.values)
            meal: mealSummary([for (final d in meals[meal]!) d.recipe.name], minutesOf(meal)),
        },
        metas: {
          for (final meal in Meal.values) meal: mealMeta(meals[meal]!.length, minutesOf(meal)),
        },
        shoppingCount: shoppingCount,
      );
    });
  }

  /// Xem ngày [date]; có [meal] thì mở sẵn bữa đó.
  void selectDate(DateTime date, {Meal? meal}) {
    final day = dateOnly(date);
    _update(
      (s) => s.copyWith(date: () => day, focus: meal == null ? null : {...s.focus, day: meal}),
    );
  }

  /// Lùi một ngày (Ngày) hoặc một tuần (Tuần).
  void previous() => _step(-1);

  /// Tới một ngày (Ngày) hoặc một tuần (Tuần).
  void next() => _step(1);

  void goToday() => _update((s) => s.copyWith(date: () => null));

  /// Mở bữa [meal] của ngày đang xem, thu gọn bữa khác.
  void focus(Meal meal) => _update((s) => s.copyWith(focus: {...s.focus, _date(): meal}));

  void setMode(PlanMode mode) => _update((s) => s.copyWith(mode: mode));

  /// Thêm [recipeId] vào cuối bữa [meal] của ngày đang xem; món đã có thì giữ nguyên.
  Future<void> addDish(Meal meal, String recipeId) async {
    final date = _date();
    final exists = ref
        .read(plannedMealsProvider)
        .any((p) => p.day == date && p.meal == meal && p.recipeId == recipeId);
    if (exists) return;
    await ref.read(plannedMealsProvider.notifier).addToPlan(recipeId, date, meal);
    ref.read(analyticsProvider).track('plan_add', {'dishes': 1});
  }

  /// Đổi [oldId] trong bữa [meal] thành [newId], giữ vị trí và khẩu phần.
  Future<void> swapDish(Meal meal, String oldId, String newId) =>
      ref.read(plannedMealsProvider.notifier).replaceInPlan(_date(), meal, oldId, newId);

  /// Bỏ [recipeId] khỏi bữa [meal] của ngày đang xem, giữ các món khác. Trả bản ghi để [undoRemove];
  /// null khi món không có trong bữa.
  Future<RemovedDish?> removeDish(Meal meal, String recipeId) async {
    final date = _date();
    final planned = ref.read(plannedMealsProvider);
    final index = planned.indexWhere(
      (p) => p.day == date && p.meal == meal && p.recipeId == recipeId,
    );
    if (index < 0) return null;
    final removed = (entry: planned[index], index: index);
    await ref.read(plannedMealsProvider.notifier).removeFromPlan(date, meal, recipeId: recipeId);
    ref.read(analyticsProvider).track('plan_remove');
    return removed;
  }

  /// Hoàn tác [removeDish]: đặt món lại đúng chỗ cũ.
  Future<void> undoRemove(RemovedDish removed) =>
      ref.read(plannedMealsProvider.notifier).restore(removed.entry, removed.index);

  /// Gợi ý món cho bữa [meal] của ngày đang xem (Tủ đồ, dụng cụ, chế độ ăn), không lặp món đã có
  /// trong ngày. Trả số món đã thêm, 0 khi không có gợi ý.
  Future<int> suggestMeal(Meal meal) async {
    final suggester = await ref.read(mealSuggesterProvider.future);
    final added = await _fill(suggester, meal, _usedToday());
    if (added.isNotEmpty) {
      ref.read(analyticsProvider).track('plan_add', {'dishes': added.length});
    }
    return added.length;
  }

  /// Gợi ý cho mọi bữa còn trống của ngày đang xem ("Gợi ý cho ngày này"): Sáng một món, Trưa và
  /// Tối cơm nhà 2 món, không lặp món trong ngày. Trả số món đã thêm.
  Future<int> suggestDay() async {
    final suggester = await ref.read(mealSuggesterProvider.future);
    final date = _date();
    final used = _usedToday();
    var count = 0;
    for (final meal in Meal.values) {
      final filled = ref.read(plannedMealsProvider).any((p) => p.day == date && p.meal == meal);
      if (filled) continue;
      final added = await _fill(suggester, meal, used);
      used.addAll(added);
      count += added.length;
    }
    if (count > 0) ref.read(analyticsProvider).track('plan_add', {'dishes': count});
    return count;
  }

  /// Thêm bữa gợi ý vào [meal], trả id các món đã thêm.
  Future<List<String>> _fill(MealSuggester suggester, Meal meal, Set<String> exclude) async {
    final prefs = MealPrefs(
      scale: meal == Meal.breakfast ? MealScale.one : MealScale.two,
      maxMinutes: null,
    );
    final suggestion = suggester(prefs, meal: meal, exclude: exclude);
    if (suggestion == null) return const [];
    final date = _date();
    final ids = [for (final r in suggestion.dishes) r.id];
    for (final id in ids) {
      await ref.read(plannedMealsProvider.notifier).addToPlan(id, date, meal);
    }
    return ids;
  }

  Set<String> _usedToday() {
    final date = _date();
    return {
      for (final p in ref.read(plannedMealsProvider))
        if (p.day == date) p.recipeId,
    };
  }

  void _step(int direction) {
    final selection = ref.read(_selectionProvider);
    final days = selection.mode == PlanMode.week ? 7 : 1;
    _update((s) => s.copyWith(date: () => addDays(_date(), direction * days)));
  }

  DateTime _date() => ref.read(_selectionProvider).date ?? dateOnly(ref.read(nowProvider));

  void _update(_Selection Function(_Selection) change) =>
      ref.read(_selectionProvider.notifier).set(change(ref.read(_selectionProvider)));
}

/// Lựa chọn trên màn; `date` null là hôm nay, `focus` là bữa người dùng mở theo từng ngày.
@immutable
class _Selection {
  const _Selection({this.date, this.mode = PlanMode.day, this.focus = const {}});

  final DateTime? date;
  final PlanMode mode;
  final Map<DateTime, Meal> focus;

  _Selection copyWith({DateTime? Function()? date, PlanMode? mode, Map<DateTime, Meal>? focus}) =>
      _Selection(
        date: date == null ? this.date : date(),
        mode: mode ?? this.mode,
        focus: focus ?? this.focus,
      );
}

class _SelectionNotifier extends Notifier<_Selection> {
  @override
  _Selection build() => const _Selection();

  void set(_Selection selection) => state = selection;
}

final _selectionProvider = NotifierProvider.autoDispose<_SelectionNotifier, _Selection>(
  _SelectionNotifier.new,
);

final planViewModelProvider = NotifierProvider.autoDispose<PlanViewModel, AsyncValue<PlanState>>(
  PlanViewModel.new,
);
