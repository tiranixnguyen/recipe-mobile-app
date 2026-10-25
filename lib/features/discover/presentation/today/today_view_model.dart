import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

Meal mealForHour(int hour) => hour < 10
    ? Meal.breakfast
    : hour < 15
    ? Meal.lunch
    : Meal.dinner;

class TodayState {
  const TodayState({
    required this.meal,
    this.maxMinutes = 30,
    this.index = 0,
    this.showReasons = false,
  });
  final Meal meal;
  final int? maxMinutes;
  final int index;
  final bool showReasons;
}

class TodayViewModel extends Notifier<TodayState> {
  @override
  TodayState build() => TodayState(meal: mealForHour(DateTime.now().hour));

  void setMeal(Meal meal) => state = TodayState(meal: meal, maxMinutes: state.maxMinutes);
  void setMinutes(int? minutes) => state = TodayState(meal: state.meal, maxMinutes: minutes);
  void next() =>
      state = TodayState(meal: state.meal, maxMinutes: state.maxMinutes, index: state.index + 1);
  void toggleReasons() => state = TodayState(
    meal: state.meal,
    maxMinutes: state.maxMinutes,
    index: state.index,
    showReasons: !state.showReasons,
  );

  Future<void> dislike(String id, DislikeReason reason) async {
    await ref.read(dislikedProvider.notifier).dislike(id, reason);
    ref.read(analyticsProvider).track('today_dislike', {'reason': reason.id});
    next();
  }

  void suggested() => ref.read(analyticsProvider).track('today_suggest', {'meal': state.meal.id});
}

final todayViewModelProvider = NotifierProvider.autoDispose<TodayViewModel, TodayState>(
  TodayViewModel.new,
);
final todayRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final state = ref.watch(todayViewModelProvider);
  final suggestions = await ref.watch(suggestionsProvider((meal: state.meal, count: 20)).future);
  return suggestions
      .where((recipe) => state.maxMinutes == null || recipe.minutes <= state.maxMinutes!)
      .toList();
});
