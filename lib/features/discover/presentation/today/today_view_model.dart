import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/domain/today.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

class TodayState {
  const TodayState({
    required this.meal,
    this.maxMinutes = 30,
    this.index = 0,
    this.showReasons = false,
  });

  final Meal meal;

  /// Null là "Thoải mái".
  final int? maxMinutes;

  /// Vị trí món chính trong danh sách gợi ý, lấy theo vòng.
  final int index;
  final bool showReasons;

  /// [maxMinutes] truyền `() => null` để bỏ giới hạn.
  TodayState copyWith({
    Meal? meal,
    ValueGetter<int?>? maxMinutes,
    int? index,
    bool? showReasons,
  }) => TodayState(
    meal: meal ?? this.meal,
    maxMinutes: maxMinutes == null ? this.maxMinutes : maxMinutes(),
    index: index ?? this.index,
    showReasons: showReasons ?? this.showReasons,
  );
}

class TodayViewModel extends Notifier<TodayState> {
  @override
  TodayState build() => TodayState(meal: mealForHour(DateTime.now().hour));

  void setMeal(Meal meal) => state = state.copyWith(meal: meal, index: 0, showReasons: false);

  void setMinutes(int? minutes) =>
      state = state.copyWith(maxMinutes: () => minutes, index: 0, showReasons: false);

  void next() => state = state.copyWith(index: state.index + 1, showReasons: false);

  void toggleReasons() => state = state.copyWith(showReasons: !state.showReasons);

  /// Món bị chê rời danh sách gợi ý nên món kế tiếp tự vào vị trí [TodayState.index];
  /// không tăng index để khỏi bỏ qua một món.
  Future<void> dislike(String id, DislikeReason reason) async {
    await ref.read(dislikedProvider.notifier).dislike(id, reason);
    ref.read(analyticsProvider).track('today_dislike', {'reason': reason.id});
    state = state.copyWith(showReasons: false);
  }

  void suggested() => ref.read(analyticsProvider).track('today_suggest', {'meal': state.meal.id});
}

final todayViewModelProvider = NotifierProvider.autoDispose<TodayViewModel, TodayState>(
  TodayViewModel.new,
);

/// Món gợi ý theo bữa và thời gian đang chọn; đổi món (index) không tải lại.
final todayRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final (meal, maxMinutes) = ref.watch(
    todayViewModelProvider.select((state) => (state.meal, state.maxMinutes)),
  );
  final suggestions = await ref.watch(suggestionsProvider((meal: meal, count: 20)).future);
  return [
    for (final recipe in suggestions)
      if (maxMinutes == null || recipe.minutes <= maxMinutes) recipe,
  ];
});
