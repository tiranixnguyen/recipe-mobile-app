import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/history.dart';

enum HistoryFilter { all, good, note }

@immutable
class HistoryState {
  const HistoryState({
    required this.entries,
    required this.recipes,
    this.query = '',
    this.filter = HistoryFilter.all,
    this.highlightId,
  });

  /// Mới nhất trước.
  final List<CookHistoryEntry> entries;
  final Map<String, Recipe> recipes;
  final String query;
  final HistoryFilter filter;

  /// Lần nấu vừa ghi (từ PantryUpdate); hiện nhãn "Vừa nấu" và snackbar một lần.
  final String? highlightId;

  String nameOf(String recipeId) => recipes[recipeId]?.name ?? recipeId;

  List<CookHistoryEntry> get visible {
    final needle = foldVietnamese(query.trim());
    return [
      for (final e in entries)
        if (_matchesFilter(e) && (needle.isEmpty || _matchesQuery(e, needle))) e,
    ];
  }

  bool _matchesFilter(CookHistoryEntry e) => switch (filter) {
    HistoryFilter.all => true,
    HistoryFilter.good => e.dishes.any((d) => d.rating == CookRating.good),
    HistoryFilter.note => e.hasNote,
  };

  bool _matchesQuery(CookHistoryEntry e, String needle) {
    if (foldVietnamese(e.mealNote).contains(needle)) return true;
    return e.dishes.any(
      (d) => foldVietnamese('${nameOf(d.recipeId)} ${d.note}').contains(needle),
    );
  }

  /// Nhóm Hôm nay / Hôm qua / Tuần này / Trước đó, theo thứ tự hiển thị; nhóm rỗng bị bỏ.
  List<(HistoryGroup, List<CookHistoryEntry>)> groups(DateTime now) {
    final byGroup = <HistoryGroup, List<CookHistoryEntry>>{};
    for (final e in visible) {
      byGroup.putIfAbsent(historyGroupOf(e.cookedAt, now), () => []).add(e);
    }
    return [
      for (final g in HistoryGroup.values)
        if (byGroup[g] case final list?) (g, list),
    ];
  }

  int monthCount(DateTime now) =>
      entries.where((e) => e.cookedAt.year == now.year && e.cookedAt.month == now.month).length;
}

class HistoryViewModel extends Notifier<HistoryState> {
  HistoryViewModel(this._highlightId);

  final String? _highlightId;
  bool _trackedOpen = false;
  bool _snackShown = false;

  bool get snackShown => _snackShown;

  @override
  HistoryState build() {
    final entries = [...ref.watch(cookHistoryProvider)]
      ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
    final recipes = ref.watch(recipesProvider).value ?? const <Recipe>[];
    if (!_trackedOpen) {
      _trackedOpen = true;
      ref.read(analyticsProvider).track('view_history', {});
    }
    return HistoryState(
      entries: List.unmodifiable(entries),
      recipes: {for (final r in recipes) r.id: r},
      highlightId: _highlightId,
    );
  }

  void search(String query) {
    state = HistoryState(
      entries: state.entries,
      recipes: state.recipes,
      query: query,
      filter: state.filter,
      highlightId: state.highlightId,
    );
  }

  void setFilter(HistoryFilter filter) {
    ref.read(analyticsProvider).track('history_filter', {'filter': filter.name});
    state = HistoryState(
      entries: state.entries,
      recipes: state.recipes,
      query: state.query,
      filter: filter,
      highlightId: state.highlightId,
    );
  }

  DateTime now() => ref.read(cookClockProvider)();

  void markSnackShown() => _snackShown = true;
}

final historyViewModelProvider = NotifierProvider.autoDispose
    .family<HistoryViewModel, HistoryState, String?>(HistoryViewModel.new);
