import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_prep.dart';
import 'package:recipe_mobile_app/features/cook/presentation/detail/detail_view_model.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

@immutable
class PrepState {
  const PrepState({
    required this.recipe,
    required this.servings,
    required this.gather,
    required this.basicSpices,
    required this.missing,
    required this.checked,
  });

  final Recipe recipe;
  final int servings;

  /// Đồ có trong tủ, lượng theo [servings].
  final List<PrepItem> gather;

  /// Gia vị cơ bản gom một dòng cuối checklist; rỗng thì không có dòng đó.
  final List<String> basicSpices;
  final List<PrepMissing> missing;

  /// Dòng đã tick: id nguyên liệu, và [PrepViewModel.spicesKey] cho dòng gia vị.
  final Set<String> checked;

  int get total => gather.length + (basicSpices.isEmpty ? 0 : 1);

  /// Số dòng đã tick, chỉ đếm dòng đang hiện (đổi Tủ đồ có thể làm mất dòng đã tick).
  int get checkedCount =>
      gather.where((i) => checked.contains(i.ingredientId)).length +
      (basicSpices.isNotEmpty && checked.contains(PrepViewModel.spicesKey) ? 1 : 0);

  /// Ghi chú thay thế của các món thiếu, theo thứ tự công thức.
  List<String> get notes => [for (final m in missing) ?m.note];
}

/// Chuẩn bị nấu (prototype `CookPrep`): chọn khẩu phần, tick đồ đã lấy ra, thêm đồ thiếu vào đi chợ.
class PrepViewModel extends Notifier<AsyncValue<PrepState>> {
  PrepViewModel(this.recipeId);

  final String recipeId;

  /// Khoá của dòng gia vị cơ bản trong [PrepState.checked].
  static const spicesKey = '_spices';

  // Giữ qua các lần build lại (Tủ đồ đổi), chỉ mất khi rời màn.
  int? _servings;
  Set<String> _checked = const {};

  @override
  AsyncValue<PrepState> build() {
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

  AsyncValue<PrepState> _prep(List<Recipe> recipes, List<Ingredient> ingredients) {
    final recipe = recipes.where((r) => r.id == recipeId).firstOrNull;
    if (recipe == null) return AsyncError(RecipeNotFound(recipeId), StackTrace.current);
    final servings = _servings ??= recipe.servings.clamp(minCookServings, maxCookServings);
    final (:gather, :basicSpices, :missing) = prepItems(
      recipe,
      servings,
      ref.watch(pantryItemsProvider),
      {for (final i in ingredients) i.id: i},
    );
    return AsyncData(
      PrepState(
        recipe: recipe,
        servings: servings,
        gather: gather,
        basicSpices: basicSpices,
        missing: missing,
        checked: _checked,
      ),
    );
  }

  void setServings(int servings) {
    _servings = servings.clamp(minCookServings, maxCookServings);
    ref.invalidateSelf();
  }

  /// Tick / bỏ tick dòng [key] (id nguyên liệu hoặc [spicesKey]).
  void toggle(String key) {
    final next = {..._checked};
    if (!next.remove(key)) next.add(key);
    _checked = Set.unmodifiable(next);
    if (state case AsyncData(:final value)) {
      state = AsyncData(
        PrepState(
          recipe: value.recipe,
          servings: value.servings,
          gather: value.gather,
          basicSpices: value.basicSpices,
          missing: value.missing,
          checked: _checked,
        ),
      );
    }
  }

  /// "Thêm vào đi chợ": cả món với khẩu phần đang chọn (Đi chợ tự trừ đồ đã có).
  Future<void> addToShopping() async {
    final servings = state.value?.servings;
    if (servings == null) return;
    await ref.read(shoppingProvider.notifier).addToShopping(recipeId, servings);
  }

  /// Món có bước hẹn giờ mà chưa xin quyền thông báo: mở màn xin quyền trước khi nấu.
  Future<bool> shouldAskNotificationPermission() async {
    final recipe = state.value?.recipe;
    if (recipe == null || !recipe.steps.any((s) => (s.timerSeconds ?? 0) > 0)) return false;
    return ref.read(shouldAskNotificationPermissionProvider)();
  }

  /// "Bắt đầu nấu": mở phiên nấu mới từ bước đầu.
  Future<void> start() async {
    final servings = state.value?.servings;
    if (servings == null) return;
    await ref.read(cookSessionProvider.notifier).startRecipe(recipeId, servings);
  }
}

final prepViewModelProvider = NotifierProvider.autoDispose
    .family<PrepViewModel, AsyncValue<PrepState>, String>(PrepViewModel.new);
