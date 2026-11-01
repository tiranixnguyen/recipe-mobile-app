/// Public API của feature Khám phá — feature khác chỉ được import file này.
///
/// - [SaveButton]: nút lưu món, đặt vào slot `action` của `RecipeCard`.
/// - [savedIdsProvider]: id món đã lưu.
/// - [savedMealsProvider]: bữa đã lưu (Today dùng để lưu bữa được gợi ý).
/// - [searchLocation]: mở màn Tìm kiếm, có thể kèm từ khoá.
/// - [savedLocation]: tab Đã lưu, có thể đánh dấu "Mới thêm" cho bữa vừa lưu.
/// - [savedMealLocation]: Chi tiết một bữa đã lưu.
/// - [todayLocation]: đường dẫn màn Hôm nay ăn gì.
/// - [todayPrefsLocation]: đường dẫn màn Gợi ý cho mình (TodayPrefs).
/// - [TodayPrefs]: tiêu chí gợi ý (F3/Today đọc qua [todayPrefsProvider]).
/// - [todayPrefsProvider]: truy cập tiêu chí đã lưu.
library;

export 'data/saved_meals.dart' show SavedMeal, SavedMealsController, savedMealsProvider;
export 'data/saved_recipes.dart' show SavedRecipesController, savedIdsProvider;
export 'data/today_prefs.dart' show TodayPrefs, TodayPrefsController, todayPrefsProvider;
export 'presentation/save_button.dart' show SaveButton;
export 'routes.dart'
    show
        discoverLocation,
        discoverRoutes,
        discoverTabRoutes,
        savedLocation,
        savedMealLocation,
        savedTabRoutes,
        searchLocation,
        todayLocation,
        todayPrefsLocation;
