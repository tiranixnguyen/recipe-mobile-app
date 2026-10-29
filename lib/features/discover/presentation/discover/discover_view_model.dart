import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Provider đồng hồ hiện tại cho Khám phá; test override để cố định thời gian.
final discoverNowProvider = Provider<DateTime>((ref) => DateTime.now());

@immutable
class DiscoverState {
  const DiscoverState({
    required this.now,
    required this.upcomingMeal,
    required this.upcomingDishes,
    required this.upcomingTotalMinutes,
    required this.upcomingIdeas,
    required this.readyDishes,
    required this.nearDishes,
    required this.pantryIngredientNames,
    required this.shoppingRequests,
    required this.shoppingForDishes,
    required this.addedShoppingIds,
  });

  /// Giờ hiện tại để xác định bữa và thứ trong tuần.
  final DateTime now;

  /// Bữa ăn sắp tới theo giờ máy: sáng, trưa hoặc tối.
  final Meal upcomingMeal;

  /// Các món đã lên thực đơn cho bữa sắp tới hôm nay.
  final List<Recipe> upcomingDishes;

  /// Tổng thời gian nấu của bữa sắp tới.
  final int upcomingTotalMinutes;

  /// Các món gợi ý nếu bữa sắp tới chưa có món.
  final List<Recipe> upcomingIdeas;

  /// Món nấu được ngay từ tủ đồ (ready).
  final List<Recipe> readyDishes;

  /// Món thiếu 1–2 thứ (near).
  final List<NearMatch> nearDishes;

  /// Tên các nguyên liệu đang có trong tủ đồ (phục vụ thẻ "Dọn tủ lạnh").
  final List<String> pantryIngredientNames;

  /// Danh sách yêu cầu đi chợ hiện có.
  final List<ShoppingRequest> shoppingRequests;

  /// Danh sách món được thêm vào đi chợ.
  final List<Recipe> shoppingForDishes;

  /// Các món đã bấm "+ Đi chợ" trong phiên hiện tại.
  final Set<String> addedShoppingIds;

  DiscoverState copyWith({
    DateTime? now,
    Meal? upcomingMeal,
    List<Recipe>? upcomingDishes,
    int? upcomingTotalMinutes,
    List<Recipe>? upcomingIdeas,
    List<Recipe>? readyDishes,
    List<NearMatch>? nearDishes,
    List<String>? pantryIngredientNames,
    List<ShoppingRequest>? shoppingRequests,
    List<Recipe>? shoppingForDishes,
    Set<String>? addedShoppingIds,
  }) {
    return DiscoverState(
      now: now ?? this.now,
      upcomingMeal: upcomingMeal ?? this.upcomingMeal,
      upcomingDishes: upcomingDishes ?? this.upcomingDishes,
      upcomingTotalMinutes: upcomingTotalMinutes ?? this.upcomingTotalMinutes,
      upcomingIdeas: upcomingIdeas ?? this.upcomingIdeas,
      readyDishes: readyDishes ?? this.readyDishes,
      nearDishes: nearDishes ?? this.nearDishes,
      pantryIngredientNames: pantryIngredientNames ?? this.pantryIngredientNames,
      shoppingRequests: shoppingRequests ?? this.shoppingRequests,
      shoppingForDishes: shoppingForDishes ?? this.shoppingForDishes,
      addedShoppingIds: addedShoppingIds ?? this.addedShoppingIds,
    );
  }
}

class DiscoverViewModel extends Notifier<AsyncValue<DiscoverState>> {
  final Set<String> _addedShoppingIds = {};

  @override
  AsyncValue<DiscoverState> build() {
    final now = ref.watch(discoverNowProvider);
    final recipesAsync = ref.watch(recipesProvider);
    final ingredientsAsync = ref.watch(ingredientsProvider);
    final matchesAsync = ref.watch(pantryMatchesProvider);
    final planned = ref.watch(plannedMealsProvider);
    final pantryIds = ref.watch(pantryItemsProvider);
    final shopping = ref.watch(shoppingProvider);

    return switch ((recipesAsync, ingredientsAsync, matchesAsync)) {
      (AsyncError(:final error, :final stackTrace), _, _) ||
      (_, AsyncError(:final error, :final stackTrace), _) ||
      (_, _, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (
        AsyncData(value: final recipes),
        AsyncData(value: final ingredients),
        AsyncData(value: final matches),
      ) =>
        _buildState(
          now: now,
          recipes: recipes,
          ingredients: ingredients,
          matches: matches,
          planned: planned,
          pantryIds: pantryIds,
          shopping: shopping,
        ),
      _ => const AsyncLoading(),
    };
  }

  AsyncValue<DiscoverState> _buildState({
    required DateTime now,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    required PantryMatches matches,
    required List<PlannedMeal> planned,
    required Set<String> pantryIds,
    required List<ShoppingRequest> shopping,
  }) {
    final meal = nextMeal(now);
    final today = dateOnly(now);
    final recipeMap = {for (final r in recipes) r.id: r};
    final ingredientMap = {for (final ing in ingredients) ing.id: ing};

    // Món đã xếp vào bữa sắp tới hôm nay
    final plannedUpcoming = planned.where((p) => p.day == today && p.meal == meal);
    final upcomingDishes = [
      for (final p in plannedUpcoming)
        if (recipeMap[p.recipeId] != null) recipeMap[p.recipeId]!,
    ];
    final upcomingTotalMinutes = upcomingDishes.fold<int>(0, (sum, r) => sum + r.minutes);

    // Món gợi ý nếu chưa có món trong bữa tới
    final readyList = matches.ready;
    final upcomingIdeas = upcomingDishes.isEmpty ? readyList.take(2).toList() : const <Recipe>[];
    final ideas = upcomingIdeas.length < 2 && recipes.isNotEmpty
        ? [
            ...upcomingIdeas,
            ...recipes.where((r) => !upcomingIdeas.contains(r)).take(2 - upcomingIdeas.length),
          ]
        : upcomingIdeas;

    // Tên nguyên liệu trong tủ
    final pantryNames = [
      for (final id in pantryIds)
        if (ingredientMap[id] != null) ingredientMap[id]!.name,
    ];

    // Món đi chợ
    final shoppingFor = [
      for (final req in shopping)
        if (recipeMap[req.recipeId] != null) recipeMap[req.recipeId]!,
    ];

    ref.read(analyticsProvider).track('view_discover');

    return AsyncData(
      DiscoverState(
        now: now,
        upcomingMeal: meal,
        upcomingDishes: upcomingDishes,
        upcomingTotalMinutes: upcomingTotalMinutes,
        upcomingIdeas: ideas,
        readyDishes: matches.ready,
        nearDishes: matches.near,
        pantryIngredientNames: pantryNames,
        shoppingRequests: shopping,
        shoppingForDishes: shoppingFor,
        addedShoppingIds: Set.unmodifiable(_addedShoppingIds),
      ),
    );
  }

  void trackBannerTap(String card) {
    ref.read(analyticsProvider).track('discover_banner_tap', {'card': card});
  }

  Future<void> addToShopping(Recipe recipe) async {
    _addedShoppingIds.add(recipe.id);
    ref.read(analyticsProvider).track('add_to_shopping_from_discover');
    await ref.read(shoppingProvider.notifier).addToShopping(recipe.id, recipe.servings);
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(addedShoppingIds: Set.unmodifiable(_addedShoppingIds)),
      );
    }
  }

  /// Bữa tiếp theo theo giờ: trước 10h là sáng, trước 14h là trưa, sau đó là tối.
  static Meal nextMeal(DateTime now) {
    final h = now.hour;
    if (h < 10) return Meal.breakfast;
    if (h < 14) return Meal.lunch;
    return Meal.dinner;
  }
}

final discoverViewModelProvider =
    NotifierProvider.autoDispose<DiscoverViewModel, AsyncValue<DiscoverState>>(
      DiscoverViewModel.new,
    );
