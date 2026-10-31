import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/cook.dart';
import 'package:recipe_mobile_app/features/discover/discover.dart';
import 'package:recipe_mobile_app/features/pantry/data/dislikes.dart';
import 'package:recipe_mobile_app/features/pantry/data/pantry_items.dart';
import 'package:recipe_mobile_app/features/pantry/domain/availability.dart';
import 'package:recipe_mobile_app/features/pantry/domain/matches.dart';
import 'package:recipe_mobile_app/features/pantry/domain/suggest.dart';
import 'package:recipe_mobile_app/features/pantry/domain/suggest_meal.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

/// Danh mục nguyên liệu theo id; null khi chưa tải xong (hoặc lỗi).
final _ingredientsByIdProvider = Provider<Map<String, Ingredient>?>((ref) {
  final ingredients = ref.watch(ingredientsProvider).value;
  if (ingredients == null) return null;
  return {for (final i in ingredients) i.id: i};
});

/// Nấu xong mà chê thì món lùi trong gợi ý chừng này ngày (prototype `CookDone`).
const demoteAfterBadRating = Duration(days: 3);

/// Giờ hiện tại để tính [demoteAfterBadRating]; test override để cố định.
final pantryClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Id món mà lần đánh giá gần nhất trong [demoteAfterBadRating] là "Chê".
final _demotedProvider = Provider<Set<String>>((ref) {
  final since = ref.watch(pantryClockProvider)().subtract(demoteAfterBadRating);
  final latest = <String, CookRating>{};
  for (final entry in ref.watch(cookHistoryProvider)) {
    if (!entry.cookedAt.isAfter(since)) continue;
    for (final dish in entry.dishes) {
      if (dish.rating case final rating?) latest[dish.recipeId] = rating;
    }
  }
  return {
    for (final MapEntry(:key, :value) in latest.entries)
      if (value == CookRating.bad) key,
  };
});

/// Món [Recipe] đủ đồ hay thiếu gì so với Tủ đồ hiện tại; tự cập nhật khi Tủ đồ đổi.
///
/// Null khi danh mục nguyên liệu chưa tải — lúc đó đừng hiện badge.
///
/// ```dart
/// final availability = ref.watch(availabilityProvider(recipe));
/// if (availability != null) AvailabilityBadge(missing: availability.missing)
/// ```
final availabilityProvider = Provider.family<Availability?, Recipe>((ref, recipe) {
  final ingredientsById = ref.watch(_ingredientsByIdProvider);
  if (ingredientsById == null) return null;
  return availabilityFor(recipe, ref.watch(pantryItemsProvider), ingredientsById);
});

/// Món nấu được ngay và món thiếu 1–2 thứ với Tủ đồ hiện tại ([matchPantry]); tự cập nhật khi Tủ
/// đồ đổi. Món vừa bị chê ([demoteAfterBadRating]) xuống cuối. Đang tải dữ liệu đóng gói thì `AsyncLoading`, lỗi thì `AsyncError`.
///
/// ```dart
/// final matches = ref.watch(pantryMatchesProvider).value;
/// matches?.ready  // List<Recipe>
/// matches?.near   // List<NearMatch>, thiếu ít lên trước
/// ```
final pantryMatchesProvider = Provider<AsyncValue<PantryMatches>>((ref) {
  final recipes = ref.watch(recipesProvider);
  final ingredients = ref.watch(ingredientsProvider);
  return switch ((recipes, ingredients)) {
    (AsyncError(:final error, :final stackTrace), _) ||
    (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
    (AsyncData(value: final recipes), AsyncData()) => AsyncData(
      matchPantry(
        recipes,
        ref.watch(pantryItemsProvider),
        ref.watch(_ingredientsByIdProvider)!,
        demoted: ref.watch(_demotedProvider),
      ),
    ),
    _ => const AsyncLoading(),
  };
});

/// Món gợi ý cho một bữa; giữ `List<Recipe>` để màn Today hiện có không phải đổi.
/// Thay đổi tủ/hồ sơ/lưu món/lịch sử/chê món sẽ tính lại danh sách.
final suggestionsProvider = FutureProvider.family<List<Recipe>, ({Meal meal, int count})>((
  ref,
  args,
) async {
  final recipes = await ref.watch(recipesProvider.future);
  final ingredients = await ref.watch(ingredientsProvider.future);
  final recent = _recent(ref);
  final profile = ref.watch(kitchenProfileProvider);
  return suggest(
    recipes,
    meal: args.meal,
    count: args.count,
    tools: profile.tools,
    diets: profile.diets,
    pantry: ref.watch(pantryItemsProvider),
    ingredientsById: {for (final ingredient in ingredients) ingredient.id: ingredient},
    saved: ref.watch(savedIdsProvider),
    disliked: recent.disliked,
    demoted: ref.watch(_demotedProvider),
    recentlyCooked: recent.cooked,
  );
});

/// Món chê ở Hôm nay ăn gì và món đã nấu trong [demoteAfterBadRating] gần đây.
({Set<String> disliked, Set<String> cooked}) _recent(Ref ref) {
  final now = ref.watch(pantryClockProvider)();
  final since = now.subtract(demoteAfterBadRating);
  bool recent(DateTime at) => !at.isBefore(since) && !at.isAfter(now);
  return (
    disliked: {
      for (final MapEntry(:key, :value) in ref.watch(dislikedProvider).entries)
        if (recent(value.at)) key,
    },
    cooked: {
      for (final entry in ref.watch(cookHistoryProvider))
        if (recent(entry.cookedAt))
          for (final dish in entry.dishes) dish.recipeId,
    },
  );
}

/// Hàm gợi ý một bữa đã gắn sẵn dữ liệu đóng gói, Tủ đồ, dụng cụ và chế độ ăn, món đã lưu, lịch sử
/// nấu và món bị chê. Tính lại khi một trong số đó đổi.
typedef MealSuggester = MealSuggestion? Function(
  MealPrefs prefs, {
  Meal? meal,
  Set<String> exclude,
});

/// Gợi ý một bữa theo tiêu chí ([suggestMeal]) cho màn Hôm nay ăn gì.
///
/// ```dart
/// final suggester = ref.watch(mealSuggesterProvider).value;
/// final suggestion = suggester?.call(prefs, meal: Meal.dinner, exclude: skipped);
/// if (suggestion?.relaxedNote case final note?) InlineBanner(text: note, …)
/// ```
final mealSuggesterProvider = FutureProvider<MealSuggester>((ref) async {
  final recipes = await ref.watch(recipesProvider.future);
  final ingredients = await ref.watch(ingredientsProvider.future);
  final ingredientsById = {for (final ingredient in ingredients) ingredient.id: ingredient};
  final recent = _recent(ref);
  final profile = ref.watch(kitchenProfileProvider);
  final pantry = ref.watch(pantryItemsProvider);
  final saved = ref.watch(savedIdsProvider);
  final demoted = ref.watch(_demotedProvider);
  return (prefs, {meal, exclude = const <String>{}}) => suggestMeal(
    recipes,
    prefs,
    pantry: pantry,
    ingredientsById: ingredientsById,
    meal: meal,
    tools: profile.tools,
    diets: profile.diets,
    exclude: exclude,
    disliked: recent.disliked,
    demoted: demoted,
    saved: saved,
    recentlyCooked: recent.cooked,
  );
});

/// Lý do cho món trong gợi ý; null khi danh mục nguyên liệu chưa tải.
/// Today dùng `ref.watch(suggestionReasonProvider(recipe))` sau khi nhận món.
final suggestionReasonProvider = Provider.family<String?, Recipe>((ref, recipe) {
  final availability = ref.watch(availabilityProvider(recipe));
  return availability == null ? null : suggestionReason(recipe, availability);
});
