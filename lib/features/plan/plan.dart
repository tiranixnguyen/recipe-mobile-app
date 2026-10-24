/// Public API của feature Thực đơn & đi chợ — feature khác chỉ được import file này.
///
/// - [plannedMealsProvider]: thực đơn; xếp món bằng `addToPlan(recipeId, day, meal)`.
/// - [shoppingProvider]: món cần đi chợ; thêm bằng `addToShopping(recipeId, servings)` (stub,
///   SHP-01 tính danh sách nguyên liệu).
/// - [shoppingLocation]: màn Đi chợ.
library;

export 'data/planned_meals.dart'
    show PlannedMeal, PlannedMealsController, dateOnly, plannedMealsProvider;
export 'data/shopping.dart' show ShoppingController, ShoppingRequest, shoppingProvider;
export 'routes.dart' show planRoutes, planTabRoutes, shoppingLocation;
