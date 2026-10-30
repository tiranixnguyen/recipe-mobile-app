/// Public API của feature Thực đơn & đi chợ — feature khác chỉ được import file này.
///
/// - [plannedMealsProvider]: thực đơn, mỗi bữa nhiều món theo thứ tự thêm; thêm món bằng
///   `addToPlan(recipeId, day, meal, servings: n)` (món đã có trong bữa thì chỉ đổi khẩu phần),
///   bỏ bằng `removeFromPlan(day, meal, recipeId: id)` (không truyền id thì bỏ cả bữa).
/// - [showAddToPlanSheet]: sheet "Thêm vào thực đơn" (chọn ngày, bữa, khẩu phần) cho Chi tiết món.
///   Thêm xong thì chuyển sang tab Thực đơn, mở đúng ngày và bữa vừa thêm.
/// - [showAddMealToPlanSheet]: như trên cho cả bữa (Hôm nay ăn gì, Đã lưu): mọi món vào một bữa.
/// - [shoppingProvider]: món cần đi chợ; thêm bằng `addToShopping(recipeId, servings)` (stub,
///   SHP-01 tính danh sách nguyên liệu).
/// - [shoppingItemsProvider]: đồ tự thêm vào đi chợ (Tủ đồ): `addIngredient(id)`, `addCustom(name)`
///   trả [AddToShoppingResult]; bỏ bằng `remove(item)`. [shoppingCountProvider] cho badge nút Đi chợ
///   (stub, SHP-01 đổi thành số dòng chưa tick).
/// - [planLocation]: tab Thực đơn, có thể mở sẵn một ngày và bữa:
///   `context.go(planLocation(date: day, meal: Meal.dinner))`.
/// - [goToPlanDay]: như trên nhưng luôn mở ngày đó, kể cả khi người dùng đã chọn ngày khác.
/// - [shoppingLocation]: màn Đi chợ.
library;

export 'data/planned_meals.dart'
    show PlannedMeal, PlannedMealsController, dateOnly, plannedMealsProvider;
export 'data/shopping.dart' show ShoppingController, ShoppingRequest, shoppingProvider;
export 'data/shopping_items.dart'
    show
        AddToShoppingResult,
        ShoppingItem,
        ShoppingItemsController,
        shoppingCountProvider,
        shoppingItemsProvider;
export 'presentation/add_to_plan/add_to_plan_sheet.dart'
    show showAddMealToPlanSheet, showAddToPlanSheet;
export 'routes.dart' show goToPlanDay, planLocation, planRoutes, planTabRoutes, shoppingLocation;
