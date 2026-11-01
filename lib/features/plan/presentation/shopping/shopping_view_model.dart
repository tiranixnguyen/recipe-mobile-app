import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/text/fold.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_items.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_sheet.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';

@immutable
class ShoppingState {
  const ShoppingState({required this.groups, required this.done, required this.inPantry});

  final List<({IngredientGroup group, List<ShoppingRow> rows})> groups;

  /// Id dòng đã tick (chỉ dòng còn trong danh sách).
  final Set<String> done;

  /// Tên thứ đã có trong Tủ đồ nên bỏ khỏi danh sách.
  final List<String> inPantry;

  List<ShoppingRow> get rows => [for (final g in groups) ...g.rows];
  int get total => rows.length;
  int get doneCount => done.length;
  bool get isEmpty => total == 0;
}

/// Danh sách đi chợ (prototype `Shopping`): tick đã mua, "Xong, cất vào tủ".
class ShoppingViewModel extends Notifier<AsyncValue<ShoppingState>> {
  @override
  AsyncValue<ShoppingState> build() {
    final done = ref.watch(shoppingDoneProvider);
    return ref.watch(shoppingSheetProvider).whenData((sheet) {
      final ids = {
        for (final g in sheet.groups)
          for (final r in g.rows) r.id,
      };
      return ShoppingState(
        groups: sheet.groups,
        done: Set.unmodifiable(done.intersection(ids)),
        inPantry: sheet.inPantry,
      );
    });
  }

  Future<void> toggle(String id) => ref.read(shoppingDoneProvider.notifier).toggle(id);

  /// "Xong, cất vào tủ": thứ đã tick có trong danh mục vào Tủ đồ, đồ tự thêm tương ứng ra khỏi đi
  /// chợ, bỏ hết dấu tick. Trả số thứ đã cất, cho snackbar.
  Future<int> complete() async {
    final current = state.value;
    if (current == null || current.doneCount == 0) return 0;
    final done = [
      for (final r in current.rows)
        if (current.done.contains(r.id)) r,
    ];
    final ingredientIds = {for (final r in done) ?r.ingredientId};
    final ingredientNames = {
      for (final i in ref.read(ingredientsProvider).value ?? const <Ingredient>[])
        if (ingredientIds.contains(i.id)) normalizeSearch(i.name),
    };
    final customNames = {
      for (final r in done)
        if (r.ingredientId == null) normalizeSearch(r.name),
    };
    final analytics = ref.read(analyticsProvider);
    final pantry = ref.read(pantryItemsProvider.notifier);
    final shopping = ref.read(shoppingItemsProvider.notifier);
    for (final id in ingredientIds) {
      await pantry.addToPantry(id);
    }
    for (final item in ref.read(shoppingItemsProvider)) {
      final bought = switch (item) {
        ShoppingItem(ingredientId: final id?) => ingredientIds.contains(id),
        ShoppingItem(name: final name?) =>
          customNames.contains(normalizeSearch(name)) ||
              ingredientNames.contains(normalizeSearch(name)),
        _ => false,
      };
      if (bought) await shopping.remove(item);
    }
    await ref.read(shoppingDoneProvider.notifier).clear();
    analytics.track('shopping_done', {'items': done.length});
    return done.length;
  }
}

final shoppingViewModelProvider =
    NotifierProvider.autoDispose<ShoppingViewModel, AsyncValue<ShoppingState>>(
      ShoppingViewModel.new,
    );
