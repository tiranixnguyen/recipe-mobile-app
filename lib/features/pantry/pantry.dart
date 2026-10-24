/// Public API của feature Tủ đồ & gợi ý — feature khác chỉ được import file này.
///
/// - [pantryItemsProvider]: id nguyên liệu đang có; thêm/bớt bằng `addToPantry`/`removeFromPantry`
///   của notifier.
/// - [availabilityProvider]: món đủ đồ hay thiếu gì, đưa vào `AvailabilityBadge`. Hàm thuần
///   [availabilityFor] cho chỗ đã có sẵn dữ liệu.
/// - [suggestionsProvider]: món gợi ý cho một bữa (stub, PAN-02 làm thật).
/// - [dislikedProvider]: chê món kèm [DislikeReason] (màn Hôm nay ăn gì).
library;

export 'data/dislikes.dart' show Dislike, DislikeReason, DislikesController, dislikedProvider;
export 'data/pantry_items.dart' show PantryItemsController, pantryItemsProvider;
export 'data/suggestions.dart' show availabilityProvider, suggestionsProvider;
export 'domain/availability.dart' show Availability, availabilityFor;
export 'domain/suggest.dart' show suggest;
export 'routes.dart' show pantryTabRoutes;
