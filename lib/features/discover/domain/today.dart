import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/data/today_prefs.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

/// Bữa sắp tới theo giờ: trước 10h là sáng, trước 15h là trưa, còn lại là tối.
Meal mealForHour(int hour) => hour < 10
    ? Meal.breakfast
    : hour < 15
    ? Meal.lunch
    : Meal.dinner;

/// Món thay cho ô [index] của bữa [dishes] khi bấm "Đổi", lấy theo thứ tự [ranked] (đã xếp hạng).
///
/// Ứng viên: cùng vai với món đang ở ô đó, chưa có trong bữa, không mang cảm giác ngược [feel]. Bỏ
/// qua món đã thử ở ô này ([tried]); thử hết thì quay vòng từ đầu. Trả món mới kèm tập đã thử mới
/// (gồm cả món vừa rời ô), null khi không có ứng viên nào.
({Recipe recipe, Set<String> tried})? swapCandidate(
  List<Recipe> ranked,
  List<Recipe> dishes,
  int index,
  Set<String> tried, {
  DishFeel? feel,
}) {
  final current = dishes[index];
  final inMeal = {for (final d in dishes) d.id};
  final opposite = feel?.opposite;
  final candidates = [
    for (final recipe in ranked)
      if (recipe.role == current.role &&
          !inMeal.contains(recipe.id) &&
          (opposite == null || recipe.feel != opposite))
        recipe,
  ];
  if (candidates.isEmpty) return null;
  final fresh = candidates.where((r) => !tried.contains(r.id)).firstOrNull;
  if (fresh != null) return (recipe: fresh, tried: {...tried, current.id, fresh.id});
  final first = candidates.first;
  return (recipe: first, tried: {current.id, first.id});
}

/// Tên một bữa trong "Hoặc thử": tối đa 2 tên, còn lại "+N món" ("A, B +1 món").
String mealNames(List<String> names) => names.length <= 2
    ? names.join(', ')
    : DiscoverStrings.todayMoreDishes(names.take(2).join(', '), names.length - 2);

/// Dải tiêu chí đang dùng ở đầu Hôm nay ăn gì: quy mô · thời gian · cảm giác · Dọn tủ lạnh · tag.
///
/// "Theo thời tiết" khi chưa bật thời tiết (#115) hiện "Theo giờ"; "Tuỳ bạn" không hiện chip.
List<String> criteriaLabels(TodayPrefs prefs) {
  final meal = prefs.meal;
  return [
    switch (meal.scale) {
      MealScale.one => DiscoverStrings.prefsScaleOne,
      MealScale.two => DiscoverStrings.prefsScaleTwo,
      MealScale.tray => DiscoverStrings.prefsScaleTray,
    },
    switch (meal.maxMinutes) {
      null => DiscoverStrings.prefsTimeNull,
      15 => DiscoverStrings.prefsTime15,
      30 => DiscoverStrings.prefsTime30,
      final minutes => DiscoverStrings.todayUnderMinutes(minutes),
    },
    if (prefs.byWeather)
      DiscoverStrings.todayByHour
    else if (meal.feel case final feel?)
      feel.label,
    if (meal.fridge) DiscoverStrings.prefsFridge,
    for (final tag in RecipeTag.values)
      if (meal.tags.contains(tag)) tag.label,
  ];
}
