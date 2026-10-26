import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/widgets/step_timer.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_timers.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/cook/domain/meal_cook.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_view_model.dart';

@immutable
class MealStepState {
  const MealStepState({
    required this.meal,
    required this.dishes,
    required this.current,
    required this.positions,
    required this.finished,
    required this.ingredients,
    required this.basicSpices,
    required this.timers,
    required this.timerEnds,
  });

  final Meal meal;

  /// Món theo thứ tự nấu.
  final List<MealDish> dishes;

  /// Món đang xem.
  final int current;

  /// Bước đang ở của từng món.
  final List<int> positions;
  final Set<int> finished;

  /// Sheet Nguyên liệu của món đang xem.
  final List<StepIngredient> ingredients;
  final List<String> basicSpices;

  /// Trạng thái đồng hồ theo `cookTimerKey(món, bước)`.
  final Map<int, StepTimerStatus> timers;

  /// Mốc hết giờ đã lưu theo `cookTimerKey(món, bước)`.
  final Map<int, DateTime> timerEnds;

  MealStepState copyWith({Map<int, StepTimerStatus>? timers}) => MealStepState(
    meal: meal,
    dishes: dishes,
    current: current,
    positions: positions,
    finished: finished,
    ingredients: ingredients,
    basicSpices: basicSpices,
    timers: timers ?? this.timers,
    timerEnds: timerEnds,
  );

  MealDish get dish => dishes[current];
  Recipe get recipe => dish.recipe;
  int get index => positions[current];
  RecipeStep get step => recipe.steps[index];
  bool get isFirst => current == 0 && index == 0;
  bool get isLastStep => index == recipe.steps.length - 1;
  bool get isLastDish => current == dishes.length - 1;

  /// Bước có hẹn giờ của mọi món: (món, bước).
  List<(int, int)> get timedSteps => [
    for (final (d, dish) in dishes.indexed)
      for (final (i, s) in dish.recipe.steps.indexed)
        if ((s.timerSeconds ?? 0) > 0) (d, i),
  ];

  /// Đồng hồ hiện ra: ở đúng bước đang xem, hoặc đang chạy / hết giờ (ở mọi món).
  bool showsTimer(int dish, int step) {
    if (dish == current && step == index) return true;
    final key = cookTimerKey(dish, step);
    return switch (timers[key]) {
      null => timerEnds.containsKey(key),
      final status => status != StepTimerStatus.idle,
    };
  }
}

/// Nấu cả bữa từng bước (prototype `MealCookStep`): tab món, mỗi món giữ bước riêng, đồng hồ của
/// mọi món chạy tiếp khi chuyển món. Đọc và ghi phiên nấu ([cookSessionProvider]).
class MealStepViewModel extends Notifier<AsyncValue<MealStepState>> {
  Map<int, StepTimerStatus> _timers = const {};

  DateTime Function() get clock => ref.read(cookClockProvider);

  @override
  AsyncValue<MealStepState> build() {
    ref.watch(keepScreenOnProvider);
    final recipes = ref.watch(recipesProvider);
    final ingredients = ref.watch(ingredientsProvider);
    return switch ((recipes, ingredients)) {
      (AsyncError(:final error, :final stackTrace), _) ||
      (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (AsyncData(value: final recipes), AsyncData(value: final ingredients)) => _step(
        recipes,
        ingredients,
      ),
      _ => const AsyncLoading(),
    };
  }

  AsyncValue<MealStepState> _step(List<Recipe> recipes, List<Ingredient> ingredients) {
    final session = ref.watch(cookSessionProvider);
    final planned = session?.planned;
    final byId = {for (final r in recipes) r.id: r};
    if (session == null || planned == null) {
      return AsyncError(const MealNotFound(), StackTrace.current);
    }
    final dishes = [
      for (final d in session.dishes)
        if (byId[d.recipeId] case final recipe? when recipe.steps.isNotEmpty)
          (recipe: recipe, servings: d.servings),
    ];
    // Món bị bỏ khỏi dữ liệu thì chỉ số trong phiên không còn đúng: coi như không có bữa.
    if (dishes.length != session.dishes.length) {
      return AsyncError(const MealNotFound(), StackTrace.current);
    }
    final positions = [
      for (final (i, d) in dishes.indexed) session.positions[i].clamp(0, d.recipe.steps.length - 1),
    ];
    final dish = dishes[session.current];
    final (:items, :basicSpices) = stepIngredients(dish.recipe, dish.servings, {
      for (final i in ingredients) i.id: i,
    });
    final now = clock();
    return AsyncData(
      MealStepState(
        meal: planned.meal,
        dishes: List.unmodifiable(dishes),
        current: session.current,
        positions: List.unmodifiable(positions),
        finished: session.finished,
        ingredients: items,
        basicSpices: basicSpices,
        timers: _timers,
        timerEnds: {
          for (final MapEntry(:key, :value) in session.timerEnds.entries)
            if (value.isAfter(now)) key: value,
        },
      ),
    );
  }

  CookSessionController get _sessions => ref.read(cookSessionProvider.notifier);

  /// Bấm tab món [dish]: xem món đó ở bước đang dở.
  Future<void> selectDish(int dish) async {
    final value = state.value;
    if (value == null || dish == value.current) return;
    await _sessions.goTo(dish, value.positions[dish]);
  }

  /// "Bước tiếp"; ở bước cuối món chưa phải món cuối thì "Sang món n": món này xong, sang món sau.
  Future<void> next() async {
    final value = state.value;
    if (value == null) return;
    if (!value.isLastStep) return _sessions.goTo(value.current, value.index + 1);
    if (value.isLastDish) return;
    await _finishDish(value, value.current);
    await _sessions.goTo(value.current + 1, value.positions[value.current + 1]);
  }

  /// "Bước trước"; ở bước đầu món thì về bước cuối món trước.
  Future<void> previous() async {
    final value = state.value;
    if (value == null || value.isFirst) return;
    if (value.index > 0) return _sessions.goTo(value.current, value.index - 1);
    final dish = value.current - 1;
    await _sessions.goTo(dish, value.dishes[dish].recipe.steps.length - 1);
  }

  /// "Xong cả bữa": mọi món xong, phiên chờ màn Hoàn thành.
  Future<void> finishMeal() async {
    final value = state.value;
    if (value == null) return;
    for (var dish = 0; dish < value.dishes.length; dish++) {
      await _finishDish(value, dish);
    }
  }

  Future<void> _finishDish(MealStepState value, int dish) async {
    await ref.read(cookTimersProvider).cancel(dish, [
      for (final (d, step) in value.timedSteps)
        if (d == dish) step,
    ]);
    await _sessions.finishDish(dish);
  }

  /// `StepTimer` của bước [step] món [dish] đổi trạng thái.
  Future<void> timerChanged(int dish, int step, StepTimerStatus status) async {
    final key = cookTimerKey(dish, step);
    _timers = Map.unmodifiable({..._timers, key: status});
    if (state case AsyncData(:final value)) state = AsyncData(value.copyWith(timers: _timers));
    final value = state.value;
    if (value == null) return;
    final recipe = value.dishes[dish].recipe;
    final seconds = recipe.steps[step].timerSeconds;
    if (seconds == null) return;
    await ref
        .read(cookTimersProvider)
        .changed(
          dish: dish,
          step: step,
          status: status,
          recipeTitle: recipe.name,
          seconds: seconds,
          savedEnd: value.timerEnds[key],
        );
  }
}

final mealStepViewModelProvider =
    NotifierProvider.autoDispose<MealStepViewModel, AsyncValue<MealStepState>>(
      MealStepViewModel.new,
    );
