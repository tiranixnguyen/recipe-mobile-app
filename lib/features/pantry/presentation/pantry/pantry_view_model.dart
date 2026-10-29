import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/widgets/tip_bubble.dart';
import 'package:recipe_mobile_app/features/pantry/data/pantry_items.dart';
import 'package:recipe_mobile_app/features/pantry/domain/pantry_list.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

/// Mẹo "nhấn giữ rồi kéo vào giỏ" cạnh nút Đi chợ; ẩn hẳn khi lần đầu thêm được bằng kéo thả.
const pantryDragTip = 'pantry.dragToShop';

@immutable
class PantryState {
  const PantryState({
    required this.query,
    required this.filter,
    required this.collapsed,
    required this.groups,
    required this.counts,
    required this.summary,
    required this.have,
    required this.needed,
    required this.shoppingCount,
  });

  final String query;
  final PantryFilter filter;

  /// Nhóm người dùng đã đóng. Đang tìm thì mọi nhóm đều mở, xem [isCollapsed].
  final Set<PantryGroupKey> collapsed;

  /// Nhóm còn chip sau khi tìm và lọc.
  final List<PantryGroupView> groups;

  /// Số trên bộ lọc "Đang có (n)", "Cần mua (n)".
  final PantryCounts counts;

  /// Số cho dòng "Có n thứ · m thứ đang cần mua".
  final PantryCounts summary;

  final Set<String> have;

  /// Id nguyên liệu trong danh sách đi chợ.
  final Set<String> needed;

  /// Badge nút Đi chợ.
  final int shoppingCount;

  bool get searching => query.trim().isNotEmpty;

  bool get noResult => groups.isEmpty;

  bool isCollapsed(PantryGroupKey key) => !searching && collapsed.contains(key);

  ChipStatus statusOf(String ingredientId) => chipStatus(ingredientId, have: have, needed: needed);
}

enum PantryShopResult {
  /// Đã thêm; có thể Hoàn tác bằng [PantryViewModel.undoAdd].
  added,

  /// Đã có trong đi chợ từ trước.
  alreadyThere,

  /// Đang có trong tủ nên không thêm.
  inPantry,
}

/// Kết quả thêm vào đi chợ để View báo snackbar: [name] là tên hiển thị, [item] để Hoàn tác.
typedef PantryShopOutcome = ({PantryShopResult result, String name, ShoppingItem item});

typedef _Ui = ({String query, PantryFilter filter, Set<PantryGroupKey> collapsed});

/// Từ khoá, bộ lọc, nhóm đóng: state riêng của màn, tách khỏi [PantryViewModel] để không mất khi
/// tủ đồ hay đi chợ đổi làm ViewModel dựng lại.
class _UiController extends Notifier<_Ui> {
  @override
  _Ui build() => (query: '', filter: PantryFilter.all, collapsed: const {});

  void update(_Ui ui) => state = ui;
}

final _uiProvider = NotifierProvider.autoDispose<_UiController, _Ui>(_UiController.new);

class PantryViewModel extends Notifier<AsyncValue<PantryState>> {
  @override
  AsyncValue<PantryState> build() {
    final ui = ref.watch(_uiProvider);
    final have = ref.watch(pantryItemsProvider);
    final shopping = ref.watch(shoppingItemsProvider);
    final shoppingCount = ref.watch(shoppingCountProvider);
    final needed = _ingredientIds(shopping);
    final customCount = shopping.where((i) => i.ingredientId == null).length;
    return ref
        .watch(ingredientsProvider)
        .whenData(
          (ingredients) => PantryState(
            query: ui.query,
            filter: ui.filter,
            collapsed: ui.collapsed,
            groups: filterPantry(
              ingredients,
              query: ui.query,
              filter: ui.filter,
              have: have,
              needed: needed,
            ),
            counts: filterCounts(ingredients, have: have, needed: needed),
            summary: pantrySummary(
              ingredients,
              have: have,
              needed: needed,
              customCount: customCount,
            ),
            have: have,
            needed: needed,
            shoppingCount: shoppingCount,
          ),
        );
  }

  _Ui get _ui => ref.read(_uiProvider);

  void _setUi({String? query, PantryFilter? filter, Set<PantryGroupKey>? collapsed}) =>
      ref.read(_uiProvider.notifier).update((
        query: query ?? _ui.query,
        filter: filter ?? _ui.filter,
        collapsed: collapsed ?? _ui.collapsed,
      ));

  void setQuery(String query) => _setUi(query: query);

  void clearQuery() => _setUi(query: '');

  void setFilter(PantryFilter filter) => _setUi(filter: filter);

  /// Mở/đóng nhóm [key].
  void toggleGroup(PantryGroupKey key) {
    final collapsed = {..._ui.collapsed};
    if (!collapsed.remove(key)) collapsed.add(key);
    _setUi(collapsed: Set.unmodifiable(collapsed));
  }

  /// Bấm chip: có ⇄ chưa có. Chip đang cần mua nghĩa là đã mua: vào tủ, ra khỏi đi chợ.
  Future<void> tap(String ingredientId) async {
    final pantry = ref.read(pantryItemsProvider.notifier);
    final status = chipStatus(
      ingredientId,
      have: ref.read(pantryItemsProvider),
      needed: _ingredientIds(ref.read(shoppingItemsProvider)),
    );
    ref.read(analyticsProvider).track('pantry_update', {
      'action': switch (status) {
        ChipStatus.have => 'remove',
        ChipStatus.none => 'add',
        ChipStatus.needed => 'bought',
      },
    });
    switch (status) {
      case ChipStatus.have:
        await pantry.removeFromPantry(ingredientId);
      case ChipStatus.none:
        await pantry.addToPantry(ingredientId);
      case ChipStatus.needed:
        await pantry.addToPantry(ingredientId);
        await ref
            .read(shoppingItemsProvider.notifier)
            .remove(ShoppingItem.ingredient(ingredientId));
    }
  }

  /// Thêm [ingredient] vào đi chợ bằng kéo vào nút Đi chợ, Shift+Enter hoặc action trợ năng (đều
  /// gửi `via: drag`). Đồ đang có trong tủ thì không thêm.
  Future<PantryShopOutcome> addToShopping(Ingredient ingredient) async {
    final item = ShoppingItem.ingredient(ingredient.id);
    PantryShopOutcome outcome(PantryShopResult result) =>
        (result: result, name: ingredient.name, item: item);

    if (ref.read(pantryItemsProvider).contains(ingredient.id)) {
      return outcome(PantryShopResult.inPantry);
    }
    final added = await ref.read(shoppingItemsProvider.notifier).addIngredient(ingredient.id);
    if (added == AddToShoppingResult.alreadyThere) return outcome(PantryShopResult.alreadyThere);

    _trackAdd('drag');
    await ref.read(tipsSeenProvider.notifier).markSeen(pantryDragTip);
    return outcome(PantryShopResult.added);
  }

  /// Nút "+ Thêm "…" vào đi chợ" khi tìm không thấy: thêm từ khoá thành tên tự gõ rồi xoá từ khoá.
  /// Từ khoá rỗng thì trả null.
  Future<PantryShopOutcome?> addQueryToShopping() async {
    final name = _ui.query.trim();
    if (name.isEmpty) return null;
    final added = await ref.read(shoppingItemsProvider.notifier).addCustom(name);
    clearQuery();
    final item = ShoppingItem.custom(name);
    if (added == AddToShoppingResult.alreadyThere) {
      return (result: PantryShopResult.alreadyThere, name: name, item: item);
    }
    _trackAdd('search');
    return (result: PantryShopResult.added, name: name, item: item);
  }

  /// Hoàn tác thêm vào đi chợ.
  Future<void> undoAdd(ShoppingItem item) => ref.read(shoppingItemsProvider.notifier).remove(item);

  void _trackAdd(String via) =>
      ref.read(analyticsProvider).track('add_to_shopping_from_pantry', {'via': via});

  static Set<String> _ingredientIds(List<ShoppingItem> items) => {
    for (final i in items) ?i.ingredientId,
  };
}

final pantryViewModelProvider =
    NotifierProvider.autoDispose<PantryViewModel, AsyncValue<PantryState>>(PantryViewModel.new);
