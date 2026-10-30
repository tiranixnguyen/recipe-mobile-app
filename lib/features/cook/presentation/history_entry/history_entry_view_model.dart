import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';

class _NotFound implements Exception {
  const _NotFound();
  @override
  String toString() => 'HistoryEntry not found';
}

/// ViewModel cho màn Chi tiết lần nấu.
class HistoryEntryViewModel extends Notifier<AsyncValue<CookHistoryEntry>> {
  HistoryEntryViewModel(this._entryId);

  final String _entryId;

  @override
  AsyncValue<CookHistoryEntry> build() {
    final all = ref.watch(cookHistoryProvider);
    final entry = all.where((e) => e.id == _entryId).firstOrNull;
    if (entry == null) return const AsyncError(_NotFound(), StackTrace.empty);
    return AsyncData(entry);
  }

  Future<void> setDishRating(int dishIdx, CookRating? rating) =>
      ref.read(cookHistoryProvider.notifier).updateDishRating(_entryId, dishIdx, rating);

  Future<void> setDishNote(int dishIdx, String note) =>
      ref.read(cookHistoryProvider.notifier).updateDishNote(_entryId, dishIdx, note);

  Future<void> setMealNote(String note) =>
      ref.read(cookHistoryProvider.notifier).updateMealNote(_entryId, note);

  Future<CookHistoryEntry?> deleteEntry() async {
    ref.read(analyticsProvider).track('history_delete', {'undo': false});
    return ref.read(cookHistoryProvider.notifier).delete(_entryId);
  }

  Future<void> restore(CookHistoryEntry entry) async {
    ref.read(analyticsProvider).track('history_delete', {'undo': true});
    await ref.read(cookHistoryProvider.notifier).restore(entry);
  }
}

final historyEntryViewModelProvider = NotifierProvider.autoDispose
    .family<HistoryEntryViewModel, AsyncValue<CookHistoryEntry>, String>(
      HistoryEntryViewModel.new,
    );
