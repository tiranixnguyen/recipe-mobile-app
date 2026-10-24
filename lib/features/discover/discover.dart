/// Public API của feature Khám phá — feature khác chỉ được import file này.
///
/// - [SaveButton]: nút lưu món, đặt vào slot `action` của `RecipeCard`.
/// - [savedIdsProvider]: id món đã lưu.
/// - [searchLocation]: mở màn Tìm kiếm, có thể kèm từ khoá.
library;

export 'data/saved_recipes.dart' show SavedRecipesController, savedIdsProvider;
export 'presentation/save_button.dart' show SaveButton;
export 'routes.dart'
    show discoverLocation, discoverRoutes, discoverTabRoutes, savedTabRoutes, searchLocation;
