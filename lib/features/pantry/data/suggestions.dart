import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/data/dislikes.dart';
import 'package:recipe_mobile_app/features/pantry/data/pantry_items.dart';
import 'package:recipe_mobile_app/features/pantry/domain/availability.dart';
import 'package:recipe_mobile_app/features/pantry/domain/matches.dart';
import 'package:recipe_mobile_app/features/pantry/domain/suggest.dart';

/// Danh mục nguyên liệu theo id; null khi chưa tải xong (hoặc lỗi).
final _ingredientsByIdProvider = Provider<Map<String, Ingredient>?>((ref) {
  final ingredients = ref.watch(ingredientsProvider).value;
  if (ingredients == null) return null;
  return {for (final i in ingredients) i.id: i};
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
/// đồ đổi. Đang tải dữ liệu đóng gói thì `AsyncLoading`, lỗi thì `AsyncError`.
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
      matchPantry(recipes, ref.watch(pantryItemsProvider), ref.watch(_ingredientsByIdProvider)!),
    ),
    _ => const AsyncLoading(),
  };
});

/// Món gợi ý cho một bữa: `ref.watch(suggestionsProvider((meal: Meal.dinner, count: 3)))`.
///
/// Stub (PAN-00), xem [suggest]; PAN-02 làm bản thật, giữ nguyên chữ ký.
final suggestionsProvider = FutureProvider.family<List<Recipe>, ({Meal meal, int count})>((
  ref,
  args,
) async {
  final recipes = await ref.watch(recipesProvider.future);
  return suggest(
    recipes,
    meal: args.meal,
    count: args.count,
    disliked: ref.watch(dislikedProvider).keys.toSet(),
  );
});
