import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _savedMealsKey = 'discover.savedMeals';

/// Bữa ăn đã lưu: danh sách id món, quy mô và tag tiêu chí khi lưu.
@immutable
class SavedMeal {
  const SavedMeal({required this.recipeIds, required this.servings, this.tags = const []});

  /// Id các món trong bữa, theo thứ tự hiển thị.
  final List<String> recipeIds;

  /// Số khẩu phần khi lưu.
  final int servings;

  /// Tag tiêu chí người dùng chọn ở màn TodayPrefs khi gợi ý bữa này.
  final List<RecipeTag> tags;

  Map<String, dynamic> toJson() => {
    'recipeIds': recipeIds,
    'servings': servings,
    'tags': [for (final t in tags) t.id],
  };

  static SavedMeal? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final rawIds = json['recipeIds'];
    final servings = json['servings'];
    if (rawIds is! List || servings is! int || servings <= 0) return null;
    final ids = [
      for (final id in rawIds)
        if (id is String && id.isNotEmpty) id,
    ];
    if (ids.isEmpty) return null;
    final rawTags = json['tags'];
    final tags = <RecipeTag>[
      if (rawTags is List)
        for (final t in rawTags)
          if (t is String)
            ...switch (RecipeTag.values.where((r) => r.id == t).toList()) {
              [final found] => [found],
              _ => [],
            },
    ];
    return SavedMeal(recipeIds: List.unmodifiable(ids), servings: servings, tags: tags);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedMeal &&
          listEquals(recipeIds, other.recipeIds) &&
          servings == other.servings &&
          listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(Object.hashAll(recipeIds), servings, Object.hashAll(tags));
}

/// Bữa ăn đã lưu; mỗi bữa là một [SavedMeal]. Mới lưu lên đầu (trước) = index 0.
class SavedMealsController extends Notifier<List<SavedMeal>> {
  @override
  List<SavedMeal> build() {
    final raw = ref.watch(localStoreProvider).readString(_savedMealsKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return List.unmodifiable([
        for (final item in list) ?SavedMeal.tryParse(item),
      ]);
    } catch (_) {
      return const [];
    }
  }

  /// Lưu bữa nếu chưa có; trả `true` nếu lưu được.
  Future<bool> saveMeal(SavedMeal meal) async {
    if (_contains(meal)) return false;
    await _save([meal, ...state]);
    return true;
  }

  /// Bỏ lưu; trả `true` nếu bỏ được.
  Future<bool> unsaveMeal(SavedMeal meal) async {
    final next = [
      for (final m in state)
        if (m != meal) m,
    ];
    if (next.length == state.length) return false;
    await _save(next);
    return true;
  }

  bool _contains(SavedMeal meal) => state.any((m) => listEquals(m.recipeIds, meal.recipeIds));

  Future<void> _save(List<SavedMeal> meals) async {
    state = List.unmodifiable(meals);
    await ref
        .read(localStoreProvider)
        .writeString(_savedMealsKey, jsonEncode([for (final m in meals) m.toJson()]));
  }
}

/// Bữa đã lưu; mới lưu lên đầu. Dùng chung với F3 (Today → lưu bữa được gợi ý).
final savedMealsProvider = NotifierProvider<SavedMealsController, List<SavedMeal>>(
  SavedMealsController.new,
);
