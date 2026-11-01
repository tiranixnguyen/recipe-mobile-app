import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/analytics.dart';
import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/text/fold.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_meals.dart';
import 'package:recipe_mobile_app/features/discover/data/saved_recipes.dart';
import 'package:recipe_mobile_app/features/discover/domain/saved.dart';
import 'package:recipe_mobile_app/features/pantry/pantry.dart';

/// Mẹo "nhấn giữ rồi kéo vào thùng rác" ở Đã lưu; ẩn hẳn khi lần đầu bỏ lưu bằng kéo thả.
const savedDragTip = 'saved.dragToTrash';

/// Một mục trong danh sách Đã lưu: món ([SavedRecipeEntry]) hoặc bữa ([SavedMealEntry]).
@immutable
sealed class SavedEntry {
  const SavedEntry();

  /// Giờ lưu; null khi lưu từ bản trước khi có giờ (nằm ở nhóm Trước đó).
  DateTime? get savedAt;

  /// Tên hiển thị, cũng là tên trong snackbar "Đã bỏ lưu …".
  String get name;

  bool matches(String foldedQuery);
}

final class SavedRecipeEntry extends SavedEntry {
  const SavedRecipeEntry({required this.recipe, this.availability, this.savedAt});

  final Recipe recipe;

  /// Độ sẵn đồ để hiện `AvailabilityBadge`; null khi thiếu quá nhiều.
  final Availability? availability;

  @override
  final DateTime? savedAt;

  @override
  String get name => recipe.name;

  @override
  bool matches(String foldedQuery) => normalizeSearch(recipe.name).contains(foldedQuery);
}

final class SavedMealEntry extends SavedEntry {
  const SavedMealEntry({required this.meal, required this.recipes});

  final SavedMeal meal;

  /// Món của bữa còn trong dữ liệu, theo thứ tự lưu.
  final List<Recipe> recipes;

  @override
  DateTime? get savedAt => meal.savedAt;

  @override
  String get name => mealName(recipes);

  @override
  bool matches(String foldedQuery) =>
      recipes.any((r) => normalizeSearch(r.name).contains(foldedQuery)) ||
      meal.tags.any((t) => normalizeSearch(t.label).contains(foldedQuery));
}

@immutable
class SavedState {
  const SavedState({required this.entries, this.query = '', this.highlightMeal});

  /// Mọi món và bữa đã lưu, mới lưu trước.
  final List<SavedEntry> entries;

  final String query;

  /// Khoá bữa vừa lưu (mở từ Hôm nay ăn gì → Xem); thẻ đó có ribbon "Mới thêm".
  final String? highlightMeal;

  bool get searching => query.trim().isNotEmpty;

  /// Mục khớp [query] (bỏ dấu), giữ thứ tự của [entries].
  List<SavedEntry> get visible {
    final q = normalizeSearch(query);
    return q.isEmpty
        ? entries
        : [
            for (final e in entries)
              if (e.matches(q)) e,
          ];
  }

  bool isHighlight(SavedEntry entry) =>
      entry is SavedMealEntry && highlightMeal != null && entry.meal.key == highlightMeal;

  /// Nhóm Hôm nay / Hôm qua / Tuần này / Trước đó theo thứ tự hiển thị; nhóm rỗng bị bỏ.
  List<(SavedGroup, List<SavedEntry>)> groups(DateTime now) {
    final byGroup = <SavedGroup, List<SavedEntry>>{};
    for (final e in visible) {
      byGroup.putIfAbsent(savedGroupOf(e.savedAt, now), () => []).add(e);
    }
    return [
      for (final g in SavedGroup.values)
        if (byGroup[g] case final list?) (g, list),
    ];
  }
}

/// Kết quả bỏ lưu: tên cho snackbar và hàm Hoàn tác.
typedef UnsaveOutcome = ({String name, Future<void> Function() undo});

/// Bỏ lưu món hoặc bữa, ghi `unsave`. Hàm Hoàn tác giữ sẵn controller (không autoDispose) và
/// analytics, nên vẫn chạy được sau khi màn đóng; lưu lại với giờ lưu cũ để mục về đúng nhóm.
Future<UnsaveOutcome> unsaveEntry(Ref ref, SavedEntry entry) async {
  final analytics = ref.read(analyticsProvider);
  final recipes = ref.read(savedIdsProvider.notifier);
  final meals = ref.read(savedMealsProvider.notifier);
  final kind = switch (entry) {
    SavedRecipeEntry() => 'recipe',
    SavedMealEntry() => 'meal',
  };
  switch (entry) {
    case SavedRecipeEntry(:final recipe):
      await recipes.unsave(recipe.id);
    case SavedMealEntry(:final meal):
      await meals.unsaveMeal(meal);
  }
  analytics.track('unsave', {'kind': kind, 'undo': false});
  return (
    name: entry.name,
    undo: () async {
      switch (entry) {
        case SavedRecipeEntry(:final recipe, :final savedAt):
          await recipes.save(recipe.id, at: savedAt);
        case SavedMealEntry(:final meal):
          await meals.saveMeal(meal);
      }
      analytics.track('unsave', {'kind': kind, 'undo': true});
    },
  );
}

class SavedViewModel extends Notifier<AsyncValue<SavedState>> {
  SavedViewModel(this._highlightMeal);

  final String? _highlightMeal;

  /// Badge chỉ hiện khi đủ đồ hoặc thiếu ít.
  static const _maxMissing = 2;

  @override
  AsyncValue<SavedState> build() {
    final query = ref.watch(_queryProvider);
    final savedIds = ref.watch(savedIdsProvider);
    final savedAt = ref.watch(savedAtProvider);
    final savedMeals = ref.watch(savedMealsProvider);

    return ref.watch(recipesProvider).whenData((allRecipes) {
      final byId = {for (final r in allRecipes) r.id: r};
      // Thứ tự gốc (mới lưu trước) làm tiêu chí phụ khi trùng giờ hoặc không có giờ.
      final entries = <SavedEntry>[
        for (final id in savedIds.toList().reversed)
          if (byId[id] case final recipe?)
            SavedRecipeEntry(
              recipe: recipe,
              availability: _badgeWorthy(ref.watch(availabilityProvider(recipe))),
              savedAt: savedAt[id],
            ),
        for (final meal in savedMeals)
          SavedMealEntry(meal: meal, recipes: [for (final id in meal.recipeIds) ?byId[id]]),
      ];
      final order = {for (final (i, e) in entries.indexed) e: i};
      entries.sort((a, b) {
        final at = a.savedAt;
        final bt = b.savedAt;
        if (at != null && bt != null && at != bt) return bt.compareTo(at);
        if ((at == null) != (bt == null)) return at == null ? 1 : -1;
        return order[a]!.compareTo(order[b]!);
      });
      return SavedState(
        entries: List.unmodifiable(entries),
        query: query,
        highlightMeal: _highlightMeal,
      );
    });
  }

  DateTime now() => ref.read(savedClockProvider)();

  void setQuery(String query) => ref.read(_queryProvider.notifier).set(query);

  /// Bỏ lưu món hoặc bữa; trả [UnsaveOutcome] để View báo snackbar và Hoàn tác.
  Future<UnsaveOutcome> unsave(SavedEntry entry) => unsaveEntry(ref, entry);
}

final savedViewModelProvider = NotifierProvider.autoDispose
    .family<SavedViewModel, AsyncValue<SavedState>, String?>(SavedViewModel.new);

/// Query dùng riêng trong màn Đã lưu; tách ra để không mất khi data đổi.
class _QueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final _queryProvider = NotifierProvider.autoDispose<_QueryController, String>(_QueryController.new);

Availability? _badgeWorthy(Availability? availability) =>
    availability != null && availability.missing.length <= SavedViewModel._maxMissing
    ? availability
    : null;

/// "A + B + 3 món" — tên bữa hiển thị.
String mealName(List<Recipe> recipes) => switch (recipes.length) {
  0 => 'Bữa ăn',
  1 => recipes[0].name,
  2 => '${recipes[0].name} + ${recipes[1].name}',
  final n => '${recipes[0].name} + ${recipes[1].name} +${n - 2} món',
};
