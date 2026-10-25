/// Public API của feature Nấu — feature khác chỉ được import file này.
///
/// - [recipeLocation]: đường dẫn tới Chi tiết món, `context.push(recipeLocation(id))`.
/// - [cookPrepLocation]: màn Chuẩn bị nấu của món, mở từ Chi tiết.
/// - [ResumeCookingBanner]: thanh "Đang nấu dở" cho màn Khám phá (stub, chưa hiện gì).
/// - [cookHistoryProvider]: món đã nấu kèm đánh giá [CookRating].
library;

export 'data/cook_history.dart'
    show CookHistoryController, CookRating, CookRecord, cookHistoryProvider;
export 'presentation/resume_cooking_banner.dart' show ResumeCookingBanner;
export 'routes.dart' show cookPrepLocation, cookRoutes, recipeLocation;
