import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';

enum HistoryFilter { all, good, note }

@immutable
class HistoryState {
  const HistoryState({
    required this.sessions,
    required this.query,
    required this.filter,
    this.highlightId,
    this.snackShown = false,
  });

  final List<CookHistoryEntry> sessions;
  final String query;
  final HistoryFilter filter;
  final String? highlightId;
  final bool snackShown;

  List<CookHistoryEntry> get filtered {
    var list = sessions;
    if (filter == HistoryFilter.good) {
      list = list.where((e) => e.dishes.any((d) => d.rating == CookRating.good)).toList();
    } else if (filter == HistoryFilter.note) {
      list = list
          .where((e) => e.mealNote.isNotEmpty || e.dishes.any((d) => d.note.isNotEmpty))
          .toList();
    }
    if (query.isNotEmpty) {
      final q = _normalize(query);
      list = list.where((e) {
        if (e.dishes.any((d) => _normalize(d.recipeId).contains(q))) return true;
        if (_normalize(e.mealNote).contains(q)) return true;
        if (e.dishes.any((d) => _normalize(d.note).contains(q))) return true;
        return false;
      }).toList();
    }
    return list;
  }

  /// Nhóm: Hôm nay / Hôm qua / Tuần này / Trước đó.
  List<(String, List<CookHistoryEntry>)> grouped(DateTime now) {
    final today = _dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final Map<String, List<CookHistoryEntry>> groups = {};
    for (final e in filtered) {
      final d = _dateOnly(e.cookedAt);
      final String label;
      if (d == today) {
        label = 'Hôm nay';
      } else if (d == yesterday) {
        label = 'Hôm qua';
      } else if (!d.isBefore(weekStart)) {
        label = 'Tuần này';
      } else {
        label = 'Trước đó';
      }
      groups.putIfAbsent(label, () => []).add(e);
    }

    const order = ['Hôm nay', 'Hôm qua', 'Tuần này', 'Trước đó'];
    return [
      for (final label in order)
        if (groups[label] case final list?) (label, list),
    ];
  }

  int thisMonthCount(DateTime now) {
    return sessions
        .where((e) => e.cookedAt.year == now.year && e.cookedAt.month == now.month)
        .length;
  }
}

String _normalize(String s) => s.toLowerCase();
DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

class HistoryViewModel extends Notifier<HistoryState> {
  HistoryViewModel(this._initialHighlightId);

  final String? _initialHighlightId;

  @override
  HistoryState build() {
    final all = ref.watch(cookHistoryProvider);
    final sorted = [...all]..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
    ref.read(analyticsProvider).track('view_history', {});
    return HistoryState(
      sessions: List.unmodifiable(sorted),
      query: '',
      filter: HistoryFilter.all,
      highlightId: _initialHighlightId,
    );
  }

  void search(String q) {
    state = HistoryState(
      sessions: state.sessions,
      query: q,
      filter: state.filter,
      highlightId: state.highlightId,
      snackShown: state.snackShown,
    );
  }

  void setFilter(HistoryFilter f) {
    ref.read(analyticsProvider).track('history_filter', {'filter': f.name});
    state = HistoryState(
      sessions: state.sessions,
      query: state.query,
      filter: f,
      highlightId: state.highlightId,
      snackShown: state.snackShown,
    );
  }

  void markSnackShown() {
    state = HistoryState(
      sessions: state.sessions,
      query: state.query,
      filter: state.filter,
      highlightId: state.highlightId,
      snackShown: true,
    );
  }

  void clearHighlight() {
    state = HistoryState(
      sessions: state.sessions,
      query: state.query,
      filter: state.filter,
      snackShown: state.snackShown,
    );
  }
}

final historyViewModelProvider = NotifierProvider.autoDispose
    .family<HistoryViewModel, HistoryState, String?>(HistoryViewModel.new);
