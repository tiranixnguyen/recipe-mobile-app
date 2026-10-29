import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/format.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/widgets/step_timer.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_timers.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/cook/domain/meal_cook.dart';
import 'package:recipe_mobile_app/features/cook/presentation/meal_prep/meal_prep_view_model.dart';
import 'package:recipe_mobile_app/features/cook/strings.dart';

/// Một việc ở chặng Sơ chế, đã sẵn chữ để hiện: "Tỏi · Băm nhỏ · 3 tép", tag món kèm phần lượng.
@immutable
class PrepItem {
  const PrepItem({
    required this.id,
    required this.ingredient,
    required this.action,
    required this.amountText,
    this.dishes = const [],
    this.children = const [],
  });

  /// `MealPrepTask.id`: khoá lưu tick.
  final String id;
  final String ingredient;

  /// Cách làm; rỗng ở việc cha.
  final String action;
  final String amountText;

  /// Món dùng tới (tên đầy đủ), kèm phần lượng "~2 tép" khi nhiều món cùng làm một việc.
  final List<({String name, String? share})> dishes;

  /// Việc con khi các món sơ chế nguyên liệu này khác cách.
  final List<PrepItem> children;

  /// Việc lá được tick: chính nó, hoặc các việc con.
  List<String> get leafIds => children.isEmpty ? [id] : [for (final c in children) c.id];

  @override
  bool operator ==(Object other) =>
      other is PrepItem &&
      other.id == id &&
      other.ingredient == ingredient &&
      other.action == action &&
      other.amountText == amountText &&
      listEquals(other.dishes, dishes) &&
      listEquals(other.children, children);

  @override
  int get hashCode => Object.hash(
    id,
    ingredient,
    action,
    amountText,
    Object.hashAll(dishes),
    Object.hashAll(children),
  );
}

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
    this.inPrep = false,
    this.prep = const [],
    this.prepDone = const {},
    this.inNotes = false,
    this.cheer = '',
  });

  final Meal meal;

  /// Món theo thứ tự nấu.
  final List<MealDish> dishes;

  /// Món đang xem (ở chặng Sơ chế, Lưu ý: món đang nấu dở; bấm "Xong sơ chế" luôn vào món đầu).
  final int current;

  /// Bước đang ở của từng món, chỉ số trong [stepsOf] (bước đứng bếp).
  final List<int> positions;
  final Set<int> finished;

  /// Sheet Nguyên liệu của món đang xem.
  final List<StepIngredient> ingredients;
  final List<String> basicSpices;

  /// Trạng thái đồng hồ theo `cookTimerKey(món, bước gốc)`.
  final Map<int, StepTimerStatus> timers;

  /// Mốc hết giờ đã lưu theo `cookTimerKey(món, bước gốc)`.
  final Map<int, DateTime> timerEnds;

  /// Đang ở chặng "Sơ chế cả bữa".
  final bool inPrep;

  /// Việc sơ chế cả bữa; rỗng khi bữa không có gì để sơ chế (không có tab Sơ chế).
  final List<PrepItem> prep;

  /// Việc lá đã tick.
  final Set<String> prepDone;

  /// Đang ở chặng Lưu ý cuối bữa.
  final bool inNotes;

  /// Câu chúc cuối chặng Lưu ý, cố định trong một lần mở màn.
  final String cheer;

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
    inPrep: inPrep,
    prep: prep,
    prepDone: prepDone,
    inNotes: inNotes,
    cheer: cheer,
  );

  bool get hasPrep => prep.isNotEmpty;

  /// Tiến độ chặng Sơ chế tính theo việc lá.
  int get prepTotal => prep.fold(0, (sum, p) => sum + p.leafIds.length);
  int get prepDoneCount =>
      prep.fold(0, (sum, p) => sum + p.leafIds.where(prepDone.contains).length);
  bool get prepFinished => hasPrep && prepDoneCount == prepTotal;

  /// Phút sơ chế cả bữa (`Recipe.prepMinutes` cộng lại), 0 khi dữ liệu không có.
  int get prepMinutes => dishes.fold(0, (sum, d) => sum + (d.recipe.prepMinutes ?? 0));

  /// Ô tick của [item]: true khi xong mọi việc lá, null khi mới xong một phần (việc cha).
  bool? checkedOf(PrepItem item) {
    final done = item.leafIds.where(prepDone.contains).length;
    if (done == 0) return false;
    return done == item.leafIds.length ? true : null;
  }

  /// Bước đứng bếp của món thứ [dish] (bỏ bước sơ chế), kèm chỉ số gốc.
  List<({int index, RecipeStep step})> stepsOf(int dish) => cookSteps(dishes[dish].recipe);

  MealDish get dish => dishes[current];
  Recipe get recipe => dish.recipe;
  List<({int index, RecipeStep step})> get steps => stepsOf(current);
  int get index => positions[current];
  RecipeStep get step => steps[index].step;

  /// Không lùi được nữa: ở chặng Sơ chế, hoặc bước đầu món đầu khi bữa không có chặng Sơ chế.
  bool get isFirst => inPrep || (!inNotes && current == 0 && index == 0 && !hasPrep);
  bool get isLastStep => index == steps.length - 1;

  /// Mọi món đã xong (tab Lưu ý có dấu check).
  bool get allFinished => finished.length >= dishes.length;

  /// Thanh tiến độ tab Lưu ý: phần món đã xong.
  double get finishedFraction => finished.length / dishes.length;

  /// Thanh tiến độ tab Sơ chế: phần việc lá đã tick.
  double get prepFraction => prepTotal == 0 ? 0 : prepDoneCount / prepTotal;

  /// Tên các món chưa xong, theo thứ tự nấu: "Xong cả bữa" hỏi lại khi còn món.
  List<String> get unfinished => [
    for (final (i, d) in dishes.indexed)
      if (!finished.contains(i)) d.recipe.name,
  ];

  /// Lưu ý cách dùng theo món, chỉ món có lưu ý.
  List<({String dish, List<String> notes})> get notes => [
    for (final d in dishes)
      if (d.recipe.notes.isNotEmpty) (dish: d.recipe.name, notes: d.recipe.notes),
  ];

  /// Bước có hẹn giờ của mọi món: (món, bước gốc).
  List<(int, int)> get timedSteps => [
    for (final (d, dish) in dishes.indexed)
      for (final (i, s) in dish.recipe.steps.indexed)
        if (!s.isPrep && (s.timerSeconds ?? 0) > 0) (d, i),
  ];

  /// Số thứ tự hiển thị ("Bước 2") của bước gốc [step] món [dish], đếm trên bước đứng bếp.
  int stepNumber(int dish, int step) => stepsOf(dish).indexWhere((s) => s.index == step) + 1;

  /// Đồng hồ hiện ra: ở đúng bước đang xem, hoặc đang chạy / hết giờ (ở mọi món, cả chặng Sơ chế,
  /// Lưu ý).
  bool showsTimer(int dish, int step) {
    if (!inPrep && !inNotes && dish == current && step == steps[index].index) return true;
    final key = cookTimerKey(dish, step);
    return switch (timers[key]) {
      null => timerEnds.containsKey(key),
      final status => status != StepTimerStatus.idle,
    };
  }
}

/// Nấu cả bữa từng bước (prototype `MealCookStep`): chặng Sơ chế chung, rồi tab món, mỗi món giữ
/// bước đứng bếp riêng, đồng hồ của mọi món chạy tiếp khi chuyển món, cuối cùng chặng Lưu ý có nút
/// "Xong cả bữa". Đọc và ghi phiên nấu
/// ([cookSessionProvider]).
class MealStepViewModel extends Notifier<AsyncValue<MealStepState>> {
  Map<int, StepTimerStatus> _timers = const {};

  /// Câu chúc chọn một lần khi mở màn, giữ nguyên khi chuyển bước, chuyển món.
  late final String _cheer =
      CookStrings.cheers[ref.read(cookRandomProvider).nextInt(CookStrings.cheers.length)];

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
        if (byId[d.recipeId] case final recipe? when cookSteps(recipe).isNotEmpty)
          (recipe: recipe, servings: d.servings),
    ];
    // Món bị bỏ khỏi dữ liệu thì chỉ số trong phiên không còn đúng: coi như không có bữa.
    if (dishes.length != session.dishes.length) {
      return AsyncError(const MealNotFound(), StackTrace.current);
    }
    final positions = [
      for (final (i, d) in dishes.indexed)
        session.positions[i].clamp(0, cookSteps(d.recipe).length - 1),
    ];
    final dish = dishes[session.current];
    final ingredientsById = {for (final i in ingredients) i.id: i};
    final (:items, :basicSpices) = stepIngredients(dish.recipe, dish.servings, ingredientsById);
    final prep = _prepItems(dishes, ingredientsById);
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
        inPrep: session.inPrep && prep.isNotEmpty,
        prep: prep,
        prepDone: session.prepDone,
        inNotes: session.inNotes,
        cheer: _cheer,
      ),
    );
  }

  /// Việc sơ chế cả bữa ([mealPrepTasks]) kèm tên nguyên liệu, tên món và lượng đã định dạng.
  static List<PrepItem> _prepItems(List<MealDish> dishes, Map<String, Ingredient> ingredientsById) {
    final names = {for (final d in dishes) d.recipe.id: d.recipe.name};
    String amount(double value, String unit) => '${formatAmount(value)} $unit';
    PrepItem item(MealPrepTask task, String ingredient) => PrepItem(
      id: task.id,
      ingredient: ingredient,
      action: task.action,
      amountText: amount(task.amount, task.unit),
      dishes: [
        for (final s in task.shares)
          (
            name: names[s.recipeId] ?? s.recipeId,
            // Một món thì tag món là đủ; nhiều món mới ghi phần của từng món.
            share: task.shares.length > 1 ? amount(s.amount, task.unit) : null,
          ),
      ],
      children: [for (final c in task.children) item(c, ingredient)],
    );
    return List.unmodifiable([
      for (final task in mealPrepTasks(dishes))
        item(task, ingredientsById[task.ingredientId]?.name ?? task.ingredientId),
    ]);
  }

  CookSessionController get _sessions => ref.read(cookSessionProvider.notifier);

  /// Bấm tab món [dish]: xem món đó ở bước đang dở.
  Future<void> selectDish(int dish) async {
    final value = state.value;
    if (value == null || (dish == value.current && !value.inPrep && !value.inNotes)) return;
    await _sessions.goTo(dish, value.positions[dish]);
  }

  /// Bấm tab Sơ chế.
  Future<void> showPrep() async {
    if (state.value?.hasPrep ?? false) await _sessions.showPrep();
  }

  /// Bấm tab Lưu ý.
  Future<void> showNotes() async {
    if (state.value != null) await _sessions.showNotes();
  }

  /// Bấm ô tick của [item]: việc lá thì đảo; việc cha thì tick hết việc con, đã đủ thì bỏ hết.
  Future<void> togglePrep(PrepItem item) async {
    final value = state.value;
    if (value == null) return;
    await _sessions.setPrepDone(item.leafIds, done: value.checkedOf(item) != true);
  }

  /// "Bước tiếp"; ở chặng Sơ chế thì "Xong sơ chế", vào món đầu (màn đã hỏi lại khi chưa tick đủ);
  /// ở bước cuối món thì "Xong món n": món này xong, sang món chưa xong kế tiếp, hết món thì sang
  /// chặng Lưu ý.
  Future<void> next() async {
    final value = state.value;
    if (value == null || value.inNotes) return;
    if (value.inPrep) return _sessions.goTo(0, value.positions[0]);
    if (!value.isLastStep) return _sessions.goTo(value.current, value.index + 1);
    await _finishDish(value, value.current);
    // Món sau món đang nấu, hết thì vòng về đầu; bỏ qua món đã xong (có thể đã nhảy tab nấu trước).
    final count = value.dishes.length;
    final dish = [
      for (var k = 1; k < count; k++) (value.current + k) % count,
    ].where((d) => !value.finished.contains(d)).firstOrNull;
    if (dish == null) return _sessions.showNotes();
    await _sessions.goTo(dish, value.positions[dish]);
  }

  /// "Xong sơ chế" khi chưa tick đủ và người dùng đồng ý: tick hết mọi việc, vào món đầu.
  Future<void> finishPrep() async {
    final value = state.value;
    if (value == null) return;
    await _sessions.setPrepDone([for (final p in value.prep) ...p.leafIds], done: true);
    await _sessions.goTo(0, value.positions[0]);
  }

  /// "Bước trước"; ở bước đầu món thì về bước cuối món trước, bước đầu món đầu thì về chặng Sơ chế;
  /// ở chặng Lưu ý thì về món đang nấu ở bước đang dở.
  Future<void> previous() async {
    final value = state.value;
    if (value == null || value.isFirst) return;
    if (value.inNotes) return _sessions.goTo(value.current, value.index);
    if (value.index > 0) return _sessions.goTo(value.current, value.index - 1);
    if (value.current == 0) return _sessions.showPrep();
    final dish = value.current - 1;
    await _sessions.goTo(dish, value.stepsOf(dish).length - 1);
  }

  /// "Xong cả bữa": mọi món xong, phiên chờ màn Hoàn thành.
  Future<void> finishMeal() async {
    final value = state.value;
    if (value == null) return;
    for (var dish = 0; dish < value.dishes.length; dish++) {
      await _cancelTimers(value, dish);
    }
    await _sessions.complete();
  }

  Future<void> _finishDish(MealStepState value, int dish) async {
    await _cancelTimers(value, dish);
    await _sessions.finishDish(dish);
  }

  /// Huỷ lịch báo hết giờ của món [dish].
  Future<void> _cancelTimers(MealStepState value, int dish) =>
      ref.read(cookTimersProvider).cancel(dish, [
        for (final (d, step) in value.timedSteps)
          if (d == dish) step,
      ]);

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
