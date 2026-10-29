import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/discover/strings.dart';

/// Bữa sắp tới theo giờ: trước 10h là sáng, trước 15h là trưa, còn lại là tối.
Meal mealForHour(int hour) => hour < 10
    ? Meal.breakfast
    : hour < 15
    ? Meal.lunch
    : Meal.dinner;

/// Dòng lý do dưới món chính: "Bạn có đủ đồ · hợp bữa tối", "Thiếu hành lá · hợp bữa tối".
///
/// [missing] là tên nguyên liệu còn thiếu (`Availability.missing`); null khi chưa tải danh mục.
String todayReason(List<String>? missing, Meal meal) => switch (missing) {
  null => DiscoverStrings.todayFitsMealOnly(meal.label.toLowerCase()),
  [] => DiscoverStrings.todayReason(DiscoverStrings.todayHasAll, meal.label.toLowerCase()),
  _ => DiscoverStrings.todayReason(
    DiscoverStrings.todayMissing(missing),
    meal.label.toLowerCase(),
  ),
};

/// Món chính ở vị trí [index] (theo vòng) và tối đa 2 món kế tiếp cho "Hoặc thử".
///
/// Null khi [items] rỗng. Ít hơn 3 món thì "Hoặc thử" không lặp lại món chính.
({T main, List<T> alternatives})? todayPick<T>(List<T> items, int index) {
  if (items.isEmpty) return null;
  final n = items.length;
  final start = index % n;
  return (
    main: items[start],
    alternatives: [for (var i = 1; i <= 2 && i < n; i++) items[(start + i) % n]],
  );
}
