import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/features/cook/data/app_review.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/data/pending_cook.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_done.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';

@immutable
class PantryUpdateState {
  const PantryUpdateState({
    required this.items,
    required this.kept,
    this.finishing = false,
  });

  final List<UsedItem> items;

  /// ingredientId còn dư (không bị xoá khỏi tủ).
  final Set<String> kept;
  final bool finishing;

  List<UsedItem> get toRemove => items.where((i) => !kept.contains(i.ingredientId)).toList();
}

class PantryUpdateViewModel extends Notifier<PantryUpdateState?> {
  @override
  PantryUpdateState? build() {
    final pending = ref.watch(pendingCookProvider);
    if (pending == null) return null;
    return PantryUpdateState(
      items: pending.usedItems,
      // Mặc định: tick "Còn" cho tất cả (người dùng bỏ tick những thứ đã hết).
      kept: Set.unmodifiable({for (final i in pending.usedItems) i.ingredientId}),
    );
  }

  void toggleKeep(String ingredientId) {
    final current = state;
    if (current == null) return;
    final next = {...current.kept};
    if (!next.remove(ingredientId)) next.add(ingredientId);
    state = PantryUpdateState(
      items: current.items,
      kept: Set.unmodifiable(next),
      finishing: current.finishing,
    );
  }

  Future<String?> finish() async {
    final current = state;
    final pending = ref.read(pendingCookProvider);
    if (current == null || pending == null || current.finishing) return null;

    state = PantryUpdateState(
      items: current.items,
      kept: current.kept,
      finishing: true,
    );

    try {
      // 1. Bỏ nguyên liệu đã hết khỏi tủ.
      final pantry = ref.read(pantryItemsProvider.notifier);
      for (final item in current.toRemove) {
        await pantry.removeFromPantry(item.ingredientId);
      }

      // 2. Tạo entry lịch sử.
      final now = ref.read(cookClockProvider)();
      final entryId = '${pending.dishes.first.recipeId}_${now.millisecondsSinceEpoch}';
      final entry = CookHistoryEntry(
        id: entryId,
        cookedAt: now,
        meal: pending.meal,
        isMeal: pending.isMeal,
        servings: pending.servings,
        minutes: pending.minutes,
        dishes: List.unmodifiable(pending.dishes),
        mealNote: pending.mealNote,
      );
      await ref.read(cookHistoryProvider.notifier).recordEntry(entry);

      // 3. Đánh dấu bữa đã nấu trong thực đơn.
      final planned = pending.planned;
      if (planned != null) {
        await ref.read(plannedMealsProvider.notifier).markCooked(
          planned.day,
          planned.meal,
          [for (final d in pending.dishes) d.recipeId],
        );
      }

      // 4. Xoá pending.
      ref.read(pendingCookProvider.notifier).set(null);

      // 5. Analytics.
      final analytics = ref.read(analyticsProvider);
      analytics.track('finish_cooking', {
        'used_up': current.toRemove.length,
        'rated': pending.dishes.any((d) => d.rating != null),
        'meal_dishes': pending.dishes.length,
      });
      for (final dish in pending.dishes) {
        if (dish.rating case final r?) {
          analytics.track('rate_recipe', {'rating': r.id});
        }
      }

      // 6. App review nếu có món ngon.
      if (pending.dishes.any((d) => d.rating == CookRating.good)) {
        await ref.read(reviewPromptProvider).maybeAsk();
      }

      return entryId;
    } finally {
      if (ref.mounted) {
        final s = state;
        if (s != null) {
          state = PantryUpdateState(items: s.items, kept: s.kept, finishing: false);
        }
      }
    }
  }
}

final pantryUpdateViewModelProvider =
    NotifierProvider.autoDispose<PantryUpdateViewModel, PantryUpdateState?>(
      PantryUpdateViewModel.new,
    );
