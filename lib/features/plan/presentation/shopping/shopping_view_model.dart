import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping.dart';
import 'package:recipe_mobile_app/features/plan/data/shopping_items.dart';
import 'package:recipe_mobile_app/features/plan/domain/shopping_list.dart';

const _doneKey = 'plan.shoppingDone';

class ShoppingGroup {
  const ShoppingGroup({required this.label, required this.items});

  final String label;
  final List<ShoppingEntry> items;
}

class ShoppingEntry {
  const ShoppingEntry({
    required this.id,
    required this.name,
    required this.subtitle,
    this.ingredientId,
  });

  final String id;
  final String name;
  final String subtitle;
  final String? ingredientId;
}

class ShoppingState {
  const ShoppingState({required this.groups, required this.doneIds, required this.total});

  final List<ShoppingGroup> groups;
  final Set<String> doneIds;
  final int total;

  int get doneCount => doneIds.length;
  bool get isEmpty => total == 0;

  ShoppingState copyWith({List<ShoppingGroup>? groups, Set<String>? doneIds, int? total}) =>
      ShoppingState(
        groups: groups ?? this.groups,
        doneIds: doneIds ?? this.doneIds,
        total: total ?? this.total,
      );
}

final shoppingViewModelProvider = NotifierProvider<ShoppingViewModel, AsyncValue<ShoppingState>>(
  ShoppingViewModel.new,
);

class ShoppingViewModel extends Notifier<AsyncValue<ShoppingState>> {
  @override
  AsyncValue<ShoppingState> build() {
    final list = ref.watch(shoppingListProvider);
    final ingredients = ref.watch(ingredientsProvider);
    final customItems = ref.watch(shoppingItemsProvider);
    final pantry = ref.watch(pantryItemsProvider);
    final doneIds = _readDone();
    if (list.isLoading || ingredients.isLoading) return const AsyncLoading();
    if (list.hasError) return AsyncError(list.error!, list.stackTrace!);
    if (ingredients.hasError) return AsyncError(ingredients.error!, ingredients.stackTrace!);
    return AsyncData(
      _makeState(
        list.value ?? const [],
        ingredients.value ?? const [],
        customItems,
        pantry,
        doneIds,
      ),
    );
  }

  Set<String> _readDone() {
    final values = ref.watch(localStoreProvider).readList(_doneKey);
    return values.whereType<String>().toSet();
  }

  ShoppingState _makeState(
    List<ShoppingLine> lines,
    List<Ingredient> ingredients,
    List<ShoppingItem> customItems,
    Set<String> pantry,
    Set<String> doneIds,
  ) {
    final byId = {for (final i in ingredients) i.id: i};
    final groups = <String, List<ShoppingEntry>>{};
    for (final line in lines) {
      final ingredient = byId[line.ingredientId];
      if (ingredient == null || ingredient.isBasicSpice || pantry.contains(ingredient.id)) continue;
      final id = _lineId(line);
      final amount = _formatAmount(line.amount);
      final entry = ShoppingEntry(
        id: id,
        ingredientId: ingredient.id,
        name: '${ingredient.name} · $amount ${line.unit}',
        subtitle: _recipeNames(line.recipeIds),
      );
      groups.putIfAbsent(ingredient.group.label, () => []).add(entry);
    }
    for (final item in customItems) {
      final name = item.name ?? byId[item.ingredientId]?.name;
      if (name == null) continue;
      final ingredient = item.ingredientId == null ? null : byId[item.ingredientId];
      groups
          .putIfAbsent(ingredient?.group.label ?? 'Khác', () => [])
          .add(
            ShoppingEntry(
              id: _itemId(item),
              name: name,
              subtitle: 'Tự thêm',
              ingredientId: item.ingredientId,
            ),
          );
    }
    final ordered = [
      for (final label in ['Rau củ', 'Đạm', 'Tinh bột', 'Gia vị', 'Khác'])
        if (groups[label]?.isNotEmpty ?? false) ShoppingGroup(label: label, items: groups[label]!),
      for (final entry in groups.entries)
        if (!['Rau củ', 'Đạm', 'Tinh bột', 'Gia vị', 'Khác'].contains(entry.key))
          ShoppingGroup(label: entry.key, items: entry.value),
    ];
    final allIds = {
      for (final group in ordered)
        for (final item in group.items) item.id,
    };
    return ShoppingState(
      groups: ordered,
      doneIds: doneIds.intersection(allIds),
      total: allIds.length,
    );
  }

  String _recipeNames(List<String> ids) => ids.join(', ');

  String _lineId(ShoppingLine line) => 'line:${line.ingredientId}:${line.unit}';
  String _itemId(ShoppingItem item) => 'item:${item.ingredientId ?? item.name}';

  String _formatAmount(double amount) => amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

  Future<void> toggle(String id) async {
    final current = state is AsyncData<ShoppingState>
        ? (state as AsyncData<ShoppingState>).value
        : null;
    if (current == null) return;
    final done = <String>{...current.doneIds};
    if (!done.add(id)) done.remove(id);
    await ref.read(localStoreProvider).writeList(_doneKey, done.toList());
    state = AsyncData(current.copyWith(doneIds: done));
  }

  Future<void> complete() async {
    final current = state is AsyncData<ShoppingState>
        ? (state as AsyncData<ShoppingState>).value
        : null;
    if (current == null) return;
    final pantry = ref.read(pantryItemsProvider.notifier);
    final custom = ref.read(shoppingItemsProvider);
    for (final group in current.groups) {
      for (final item in group.items.where((item) => current.doneIds.contains(item.id))) {
        if (item.ingredientId != null) await pantry.addToPantry(item.ingredientId!);
        final customItem = custom.where((candidate) => _itemId(candidate) == item.id).firstOrNull;
        if (customItem != null) await ref.read(shoppingItemsProvider.notifier).remove(customItem);
      }
    }
    await ref.read(localStoreProvider).writeList(_doneKey, const []);
  }
}
