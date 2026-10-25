/// Public API của feature Thực đơn & đi chợ — feature khác chỉ được import file này.
///
/// - [plannedMealsProvider]: thực đơn, mỗi bữa nhiều món theo thứ tự thêm; thêm món bằng
///   `addToPlan(recipeId, day, meal, servings: n)` (món đã có trong bữa thì chỉ đổi khẩu phần),
///   bỏ bằng `removeFromPlan(day, meal, recipeId: id)` (không truyền id thì bỏ cả bữa).
/// - [showAddToPlanSheet]: sheet "Thêm vào thực đơn" (chọn ngày, bữa, khẩu phần) cho Chi tiết món.
/// - [shoppingProvider]: món cần đi chợ; thêm bằng `addToShopping(recipeId, servings)` (stub,
///   SHP-01 tính danh sách nguyên liệu).
///   Thêm xong thì chuyển sang tab Thực đơn, mở đúng ngày vừa thêm.
/// - [planLocation]: tab Thực đơn, có thể mở sẵn một ngày trong tuần: `context.go(planLocation(day: 2))`.
/// - [shoppingLocation]: màn Đi chợ.
library;

export 'data/planned_meals.dart'
    show PlannedMeal, PlannedMealsController, dateOnly, plannedMealsProvider;
export 'data/shopping.dart' show ShoppingController, ShoppingRequest, shoppingProvider;
export 'presentation/add_to_plan/add_to_plan_sheet.dart' show showAddToPlanSheet;
export 'routes.dart' show planLocation, planRoutes, planTabRoutes, shoppingLocation;
