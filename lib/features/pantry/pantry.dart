/// Public API của feature Tủ đồ & gợi ý — feature khác chỉ được import file này.
///
/// - [pantryItemsProvider]: id nguyên liệu đang có; thêm/bớt bằng `addToPantry`/`removeFromPantry`
///   của notifier.
/// - [availabilityProvider]: món đủ đồ hay thiếu gì, đưa vào `AvailabilityBadge`. Hàm thuần
///   [availabilityFor] cho chỗ đã có sẵn dữ liệu.
/// - [pantryMatchesProvider]: món nấu được ngay và món thiếu 1–2 thứ (Khám phá).
/// - [pantryLocation]: tab Tủ đồ, `context.go(pantryLocation)`.
/// - [suggestionsProvider]: món gợi ý cho một bữa; [suggestionReasonProvider] nêu lý do có căn cứ.
/// - [dislikedProvider]: chê món kèm [DislikeReason] (màn Hôm nay ăn gì).
/// - [mealSuggesterProvider]: gợi ý một bữa theo [MealPrefs] (quy mô, thời gian, cảm giác, tag), trả
///   [MealSuggestion] kèm câu "Đã nới…" khi phải nới tiêu chí. Hàm thuần [suggestMeal].
library;

export 'data/dislikes.dart' show Dislike, DislikeReason, DislikesController, dislikedProvider;
export 'data/pantry_items.dart' show PantryItemsController, pantryItemsProvider;
export 'data/suggestions.dart'
    show
        MealSuggester,
        availabilityProvider,
        mealSuggesterProvider,
        pantryMatchesProvider,
        suggestionsProvider,
        suggestionReasonProvider;
export 'domain/availability.dart' show Availability, availabilityFor;
export 'domain/matches.dart' show NearMatch, PantryMatches;
export 'domain/suggest.dart' show suggest, suggestionReason;
export 'domain/suggest_meal.dart' show MealPrefs, MealScale, MealSuggestion, suggestMeal;
export 'routes.dart' show pantryLocation, pantryTabRoutes;
