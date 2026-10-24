import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/pantry/data/pantry_items.dart';
import 'package:recipe_mobile_app/features/pantry/data/suggestions.dart';
import 'package:recipe_mobile_app/features/pantry/domain/matches.dart';

/// Một nhóm chip trong Tủ đồ.
typedef PantryGroup = ({IngredientGroup group, List<Ingredient> items});

@immutable
class PantryState {
  const PantryState({
    required this.groups,
    required this.have,
    required this.ready,
    required this.near,
  });

  /// Nhóm theo thứ tự [IngredientGroup], bỏ gia vị cơ bản (luôn coi là có) và nhóm rỗng.
  final List<PantryGroup> groups;

  /// Id nguyên liệu đang bật.
  final Set<String> have;

  /// Món nấu được ngay.
  final List<Recipe> ready;

  /// Tối đa [PantryViewModel.nearLimit] món thiếu 1–2 thứ, thiếu ít lên trước.
  final List<NearMatch> near;
}

class PantryViewModel extends Notifier<AsyncValue<PantryState>> {
  static const nearLimit = 3;

  @override
  AsyncValue<PantryState> build() {
    final ingredients = ref.watch(ingredientsProvider);
    final matches = ref.watch(pantryMatchesProvider);
    return switch ((ingredients, matches)) {
      (AsyncError(:final error, :final stackTrace), _) ||
      (_, AsyncError(:final error, :final stackTrace)) => AsyncError(error, stackTrace),
      (AsyncData(value: final ingredients), AsyncData(value: final matches)) => AsyncData(
        PantryState(
          groups: _group(ingredients),
          have: ref.watch(pantryItemsProvider),
          ready: matches.ready,
          near: matches.near.take(nearLimit).toList(growable: false),
        ),
      ),
      _ => const AsyncLoading(),
    };
  }

  /// Bật nguyên liệu chưa có, tắt nguyên liệu đang có; lưu ngay vào `LocalStore`.
  Future<void> toggle(String ingredientId) {
    final pantry = ref.read(pantryItemsProvider.notifier);
    return ref.read(pantryItemsProvider).contains(ingredientId)
        ? pantry.removeFromPantry(ingredientId)
        : pantry.addToPantry(ingredientId);
  }

  static List<PantryGroup> _group(List<Ingredient> ingredients) => [
    for (final group in IngredientGroup.values)
      if (ingredients.where((i) => i.group == group && !i.isBasicSpice).toList() case final items
          when items.isNotEmpty)
        (group: group, items: items),
  ];
}

final pantryViewModelProvider =
    NotifierProvider.autoDispose<PantryViewModel, AsyncValue<PantryState>>(PantryViewModel.new);
