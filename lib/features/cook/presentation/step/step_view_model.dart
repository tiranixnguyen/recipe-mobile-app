import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/widgets/step_timer.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_timers.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';

@immutable
class CookStepState {
  const CookStepState({
    required this.recipe,
    required this.servings,
    required this.index,
    required this.ingredients,
    required this.basicSpices,
    required this.timers,
    this.timerEnds = const {},
  });

  final Recipe recipe;
  final int servings;

  /// Chỉ số bước đang xem.
  final int index;

  /// Sheet Nguyên liệu, lượng theo [servings].
  final List<StepIngredient> ingredients;
  final List<String> basicSpices;

  /// Trạng thái đồng hồ theo chỉ số bước; bước chưa bấm hẹn giờ thì không có.
  final Map<int, StepTimerStatus> timers;

  /// Mốc hết giờ đã lưu của đồng hồ đang chạy, theo chỉ số bước: mở lại màn thì chạy tiếp.
  final Map<int, DateTime> timerEnds;

  CookStepState copyWith({Map<int, StepTimerStatus>? timers}) => CookStepState(
    recipe: recipe,
    servings: servings,
    index: index,
    ingredients: ingredients,
    basicSpices: basicSpices,
    timers: timers ?? this.timers,
    timerEnds: timerEnds,
  );

  List<RecipeStep> get steps => recipe.steps;
  RecipeStep get step => steps[index];
  bool get isFirst => index == 0;
  bool get isLast => index == steps.length - 1;

  /// Bước có hẹn giờ, theo thứ tự.
  List<int> get timedSteps => [
    for (final (i, s) in steps.indexed)
      if ((s.timerSeconds ?? 0) > 0) i,
  ];

  /// Đồng hồ của bước [i] hiện ra: ở đúng bước đó, hoặc đang chạy / hết giờ (ở mọi bước).
  bool showsTimer(int i) =>
      i == index ||
      switch (timers[i]) {
        null => timerEnds.containsKey(i),
        final status => status != StepTimerStatus.idle,
      };
}

/// Nấu từng bước một món (prototype `CookStep`). Bước đang ở lưu trong phiên nấu
/// ([cookSessionProvider]) để "Nấu tiếp" từ Khám phá; màn hình luôn sáng khi màn còn mở.
class StepViewModel extends Notifier<AsyncValue<CookStepState>> {
  StepViewModel(this.recipeId);

  final String recipeId;

  /// Giữ qua các lần build lại (sang bước khác), chỉ mất khi rời màn.
  Map<int, StepTimerStatus> _timers = const {};

  /// Giờ cho `StepTimer`, cùng đồng hồ với lịch báo hết giờ.
  DateTime Function() get clock => ref.read(cookClockProvider);

  @override
  AsyncValue<CookStepState> build() {
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

  AsyncValue<CookStepState> _step(List<Recipe> recipes, List<Ingredient> ingredients) {
    final recipe = recipes.where((r) => r.id == recipeId).firstOrNull;
    if (recipe == null || recipe.steps.isEmpty) {
      return AsyncError(RecipeNotFound(recipeId), StackTrace.current);
    }
    final session = _session;
    final servings = session?.currentDish.servings ?? recipe.servings;
    final index = (session?.positions[0] ?? 0).clamp(0, recipe.steps.length - 1);
    final (:items, :basicSpices) = stepIngredients(recipe, servings, {
      for (final i in ingredients) i.id: i,
    });
    final now = clock();
    final ends = session?.timerEnds ?? const <int, DateTime>{};
    return AsyncData(
      CookStepState(
        recipe: recipe,
        servings: servings,
        index: index,
        ingredients: items,
        basicSpices: basicSpices,
        timers: _timers,
        timerEnds: {
          for (var i = 0; i < recipe.steps.length; i++)
            if (ends[cookTimerKey(0, i)] case final at? when at.isAfter(now)) i: at,
        },
      ),
    );
  }

  /// Phiên nấu của đúng món này; null khi mở thẳng (link cũ) hoặc phiên đang nấu món khác.
  CookSession? get _session {
    final session = ref.watch(cookSessionProvider);
    if (session == null || session.isMeal || session.currentDish.recipeId != recipeId) return null;
    return session;
  }

  Future<void> next() => _goTo(1);

  Future<void> previous() => _goTo(-1);

  Future<void> _goTo(int delta) async {
    final value = state.value;
    if (value == null) return;
    final target = (value.index + delta).clamp(0, value.steps.length - 1);
    final sessions = ref.read(cookSessionProvider.notifier);
    if (ref.read(cookSessionProvider) case final s?
        when !s.isMeal && s.currentDish.recipeId == recipeId) {
      await sessions.goTo(0, target);
    } else {
      // Mở thẳng màn này (không qua Chuẩn bị): bắt đầu phiên với khẩu phần chuẩn của món.
      await sessions.startRecipe(recipeId, value.servings);
      await sessions.goTo(0, target);
    }
  }

  /// "Xong" ở bước cuối: đánh dấu món đã nấu xong (phiên chờ màn Hoàn thành), huỷ lịch báo hết giờ.
  Future<void> finish() async {
    final value = state.value;
    if (value == null) return;
    final sessions = ref.read(cookSessionProvider.notifier);
    if (_session == null) await sessions.startRecipe(recipeId, value.servings);
    await ref.read(cookTimersProvider).cancel(0, value.timedSteps);
    await sessions.finishDish(0);
  }

  /// `StepTimer` của bước [step] đổi trạng thái; xem [CookTimers.changed].
  Future<void> timerChanged(int step, StepTimerStatus status) async {
    _timers = Map.unmodifiable({..._timers, step: status});
    if (state case AsyncData(:final value)) state = AsyncData(value.copyWith(timers: _timers));
    final value = state.value;
    final seconds = value?.steps[step].timerSeconds;
    if (value == null || seconds == null) return;
    // Mở thẳng (chưa có phiên): bấm hẹn giờ là đang nấu, mở phiên để lưu mốc hết giờ.
    if (_session == null) {
      await ref.read(cookSessionProvider.notifier).startRecipe(recipeId, value.servings);
    }
    await ref
        .read(cookTimersProvider)
        .changed(
          dish: 0,
          step: step,
          status: status,
          recipeTitle: value.recipe.name,
          seconds: seconds,
          savedEnd: value.timerEnds[step],
        );
  }
}

final stepViewModelProvider = NotifierProvider.autoDispose
    .family<StepViewModel, AsyncValue<CookStepState>, String>(StepViewModel.new);
