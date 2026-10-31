import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';

@immutable
class HistoryEntryState {
  const HistoryEntryState({required this.entry, required this.recipes});

  /// Null khi đã bị xoá hoặc id không có (link cũ).
  final CookHistoryEntry? entry;
  final Map<String, Recipe> recipes;

  String nameOf(String recipeId) => recipes[recipeId]?.name ?? recipeId;
}

/// ViewModel cho màn Chi tiết lần nấu: sửa điểm/ghi chú tự lưu, xoá kèm Hoàn tác.
class HistoryEntryViewModel extends Notifier<HistoryEntryState> {
  HistoryEntryViewModel(this.entryId);

  final String entryId;

  @override
  HistoryEntryState build() {
    final entry = ref.watch(cookHistoryProvider).where((e) => e.id == entryId).firstOrNull;
    final recipes = ref.watch(recipesProvider).value ?? const <Recipe>[];
    return HistoryEntryState(entry: entry, recipes: {for (final r in recipes) r.id: r});
  }

  Future<void> setDishRating(int index, CookRating? rating) =>
      ref.read(cookHistoryProvider.notifier).updateDishRating(entryId, index, rating);

  Future<void> setDishNote(int index, String note) =>
      ref.read(cookHistoryProvider.notifier).updateDishNote(entryId, index, note);

  Future<void> setMealNote(String note) =>
      ref.read(cookHistoryProvider.notifier).updateMealNote(entryId, note);

  /// Xoá lần nấu; trả về mục đã xoá để Hoàn tác, null khi không có (đã xoá từ nơi khác).
  Future<CookHistoryEntry?> delete() async {
    final removed = await ref.read(cookHistoryProvider.notifier).delete(entryId);
    if (removed != null) ref.read(analyticsProvider).track('history_delete', {'undo': false});
    return removed;
  }

  Future<void> restore(CookHistoryEntry entry) async {
    await ref.read(cookHistoryProvider.notifier).restore(entry);
    ref.read(analyticsProvider).track('history_delete', {'undo': true});
  }
}

final historyEntryViewModelProvider = NotifierProvider.autoDispose
    .family<HistoryEntryViewModel, HistoryEntryState, String>(HistoryEntryViewModel.new);
