import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_prep.dart';
import 'package:recipe_mobile_app/features/cook/domain/meal_cook.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

/// Bữa không có món nào trong Thực đơn (link cũ, món đã bị bỏ).
class MealNotFound implements Exception {
  const MealNotFound();
}

@immutable
class MealPrepState {
  const MealPrepState({
    required this.slot,
    required this.dishes,
    required this.suggested,
    required this.servings,
    required this.gather,
    required this.basicSpices,
    required this.missing,
    required this.checked,
    required this.hasPrep,
  });

  final PlannedSlot slot;

  /// Món theo thứ tự nấu đang chọn, khẩu phần là [servings].
  final List<MealDish> dishes;

  /// Id món theo thứ tự gợi ý ([suggestCookOrder]).
  final List<String> suggested;
  final int servings;

  /// Đồ có trong tủ, cộng cho cả bữa.
  final List<MealGatherItem> gather;
  final List<String> basicSpices;
  final List<PrepMissing> missing;

  /// Dòng đã tick: id nguyên liệu và [MealPrepViewModel.spicesKey].
  final Set<String> checked;

  /// Bữa có việc sơ chế ([mealPrepTasks]): bắt đầu ở chặng Sơ chế.
  final bool hasPrep;

  /// Người dùng đã kéo đổi thứ tự khác gợi ý.
  bool get reordered => !listEquals([for (final d in dishes) d.recipe.id], suggested);

  /// Nấu lần lượt từng món nên cộng thời gian; prototype ghi "khoảng".
  int get minutes => dishes.fold(0, (sum, d) => sum + d.recipe.minutes);

  /// Phút sơ chế cả bữa (`Recipe.prepMinutes` cộng lại); phần còn lại của [minutes] là nấu.
  int get prepMinutes => dishes.fold(0, (sum, d) => sum + (d.recipe.prepMinutes ?? 0));
  int get cookMinutes => minutes - prepMinutes;

  /// Dụng cụ của cả bữa, không trùng: "Bếp từ, Nồi cơm điện".
  String? get tools {
    final labels = {
      for (final d in dishes)
        for (final t in d.recipe.tools) t.shortLabel,
    };
    return labels.isEmpty ? null : labels.join(', ');
  }

  int get total => gather.length + (basicSpices.isEmpty ? 0 : 1);

  int get checkedCount =>
      gather.where((i) => checked.contains(i.ingredientId)).length +
      (basicSpices.isNotEmpty && checked.contains(MealPrepViewModel.spicesKey) ? 1 : 0);

  /// Đã tick hết "Lấy đồ ra · cả bữa"; chưa thì hỏi lại trước khi bắt đầu.
  bool get allGathered => checkedCount >= total;

  List<String> get notes => [for (final m in missing) ?m.note];

  String nameOf(String recipeId) =>
      dishes.where((d) => d.recipe.id == recipeId).firstOrNull?.recipe.name ?? recipeId;
}

/// Chuẩn bị nấu cả bữa (prototype `MealCookPrep`): thứ tự nấu kéo thả được, khẩu phần cả bữa,
/// đồ cần lấy ra cho mọi món.
class MealPrepViewModel extends Notifier<AsyncValue<MealPrepState>> {
  MealPrepViewModel(this.slot);

  final PlannedSlot slot;

  static const spicesKey = '_spices';

  // Giữ qua các lần build lại (Tủ đồ, thực đơn đổi), chỉ mất khi rời màn.
  List<String>? _order;
  int? _servings;
  Set<String> _checked = const {};

  @override
  AsyncValue<MealPrepState> build() {
    final recipes = ref.watch(recipesProvider);
    final ingredients = ref.watch(ingredientsProvider);
    return switch ((recipes, ingredients)) {
      (AsyncError(:final error, :final stackTrace), _) ||
      (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (AsyncData(value: final recipes), AsyncData(value: final ingredients)) => _prep(
        recipes,
        ingredients,
      ),
      _ => const AsyncLoading(),
    };
  }

  AsyncValue<MealPrepState> _prep(List<Recipe> recipes, List<Ingredient> ingredients) {
    final byId = {for (final r in recipes) r.id: r};
    final day = dateOnly(slot.day);
    final planned = [
      for (final p in ref.watch(plannedMealsProvider))
        if (p.day == day && p.meal == slot.meal)
          if (byId[p.recipeId] case final recipe?) (recipe: recipe, servings: p.servings),
    ];
    if (planned.isEmpty) return AsyncError(const MealNotFound(), StackTrace.current);

    final servings = _servings ??= planned
        .map((d) => d.servings)
        .reduce((a, b) => a > b ? a : b)
        .clamp(minCookServings, maxCookServings);
    final suggested = [for (final d in suggestCookOrder(planned)) d.recipe.id];
    // Món thêm / bỏ khỏi bữa khi đang mở màn: giữ thứ tự đã kéo, món mới vào cuối.
    final order = [
      ...?_order?.where(suggested.contains),
      ...suggested.where((id) => !(_order?.contains(id) ?? false)),
    ];
    _order = order;
    final dishes = [for (final id in order) (recipe: byId[id]!, servings: servings)];
    final (:gather, :basicSpices, :missing) = mealPrepItems(
      dishes,
      ref.watch(pantryItemsProvider),
      {for (final i in ingredients) i.id: i},
    );
    return AsyncData(
      MealPrepState(
        slot: slot,
        dishes: List.unmodifiable(dishes),
        suggested: List.unmodifiable(suggested),
        servings: servings,
        gather: gather,
        basicSpices: basicSpices,
        missing: missing,
        checked: _checked,
        hasPrep: mealPrepTasks(dishes).isNotEmpty,
      ),
    );
  }

  /// Kéo món ở vị trí [from] tới vị trí [to] (chỉ số sau khi đã bỏ món ra khỏi chỗ cũ).
  void move(int from, int to) {
    final order = [...?_order];
    if (from < 0 || from >= order.length) return;
    final id = order.removeAt(from);
    order.insert(to.clamp(0, order.length), id);
    _order = order;
    ref.invalidateSelf();
  }

  /// "Dùng thứ tự gợi ý".
  void useSuggestedOrder() {
    _order = null;
    ref.invalidateSelf();
  }

  void setServings(int servings) {
    _servings = servings.clamp(minCookServings, maxCookServings);
    ref.invalidateSelf();
  }

  void toggle(String key) {
    final next = {..._checked};
    if (!next.remove(key)) next.add(key);
    _checked = Set.unmodifiable(next);
    ref.invalidateSelf();
  }

  /// "Thêm vào đi chợ": mọi món của bữa với khẩu phần đang chọn.
  Future<void> addToShopping() async {
    final value = state.value;
    if (value == null) return;
    final shopping = ref.read(shoppingProvider.notifier);
    for (final d in value.dishes) {
      await shopping.addToShopping(d.recipe.id, d.servings);
    }
  }

  Future<bool> shouldAskNotificationPermission() async {
    final value = state.value;
    final timed = value?.dishes.any((d) => d.recipe.steps.any((s) => (s.timerSeconds ?? 0) > 0));
    if (timed != true) return false;
    return ref.read(shouldAskNotificationPermissionProvider)();
  }

  /// "Bắt đầu sơ chế" ("Bắt đầu: tên món đầu" khi bữa không có gì để sơ chế): mở phiên nấu cả
  /// bữa theo thứ tự đang chọn.
  Future<void> start() async {
    final value = state.value;
    if (value == null) return;
    await ref
        .read(cookSessionProvider.notifier)
        .startMeal(
          [for (final d in value.dishes) (recipeId: d.recipe.id, servings: d.servings)],
          slot,
          prep: value.hasPrep,
        );
    ref.read(analyticsProvider).track('start_cooking', {
      'servings': value.servings,
      'steps': value.dishes.fold<int>(0, (sum, d) => sum + d.recipe.steps.length),
      'meal_dishes': value.dishes.length,
    });
  }
}

final mealPrepViewModelProvider = NotifierProvider.autoDispose
    .family<MealPrepViewModel, AsyncValue<MealPrepState>, PlannedSlot>(MealPrepViewModel.new);
