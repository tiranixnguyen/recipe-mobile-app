/// Public API của feature Nấu — feature khác chỉ được import file này.
///
/// - [recipeLocation]: đường dẫn tới Chi tiết món, `context.push(recipeLocation(id))`.
/// - [cookPrepLocation]: màn Chuẩn bị nấu của món, mở từ Chi tiết.
/// - [cookStepLocation]: nấu từng bước, mở ở bước đang dở.
/// - [mealCookLocation]: nấu cả bữa của Thực đơn ("Nấu bữa này").
/// - [ResumeCookingBanner]: thanh "Đang nấu dở · Nấu tiếp" cho màn Khám phá; không nấu dở thì ẩn.
/// - [cookHistoryProvider]: lịch sử nấu kèm đánh giá.
/// - [historyTabRoutes]: routes cho tab Lịch sử, dùng trong [appTabs].
/// - [pantryUpdateLocation]: màn cập nhật tủ sau khi nấu xong.
library;

export 'data/cook_history.dart'
    show CookedDish, CookHistoryController, CookHistoryEntry, CookRating, cookHistoryProvider;
export 'data/pending_cook.dart' show PendingCookData, pendingCookProvider;
export 'presentation/history/history_screen.dart' show HistoryScreen;
export 'presentation/history_entry/history_entry_screen.dart' show HistoryEntryScreen;
export 'presentation/pantry_update/pantry_update_screen.dart' show PantryUpdateScreen;
export 'presentation/resume_cooking_banner.dart' show ResumeCookingBanner;
export 'routes.dart'
    show
        cookPrepLocation,
        cookRoutes,
        cookStepLocation,
        historyEntryLocation,
        historyLocation,
        historyTabRoutes,
        mealCookLocation,
        pantryUpdateLocation,
        recipeLocation;
