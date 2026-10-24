import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _mealsKey = 'plan.meals';

/// Bỏ giờ phút, chỉ giữ ngày (giờ địa phương).
DateTime dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

/// Một món đã xếp vào một bữa của một ngày.
@immutable
class PlannedMeal {
  PlannedMeal({required DateTime day, required this.meal, required this.recipeId})
    : day = dateOnly(day);

  /// Luôn là 0h của ngày đó.
  final DateTime day;
  final Meal meal;
  final String recipeId;

  Map<String, dynamic> toJson() => {
    'day': day.toIso8601String().substring(0, 10),
    'meal': meal.id,
    'recipeId': recipeId,
  };

  /// Trả null khi bản ghi hỏng.
  static PlannedMeal? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final day = DateTime.tryParse(json['day'] as String? ?? '');
    final meal = Meal.tryParse(json['meal'] as String? ?? '');
    final recipeId = json['recipeId'];
    if (day == null || meal == null || recipeId is! String) return null;
    return PlannedMeal(day: day, meal: meal, recipeId: recipeId);
  }

  @override
  bool operator ==(Object other) =>
      other is PlannedMeal && other.day == day && other.meal == meal && other.recipeId == recipeId;

  @override
  int get hashCode => Object.hash(day, meal, recipeId);

  @override
  String toString() => 'PlannedMeal($day, $meal, $recipeId)';
}

/// Thực đơn: mỗi ô (ngày, bữa) tối đa một món.
class PlannedMealsController extends Notifier<List<PlannedMeal>> {
  @override
  List<PlannedMeal> build() {
    final raw = ref.watch(localStoreProvider).readString(_mealsKey);
    if (raw == null) return const [];
    try {
      return List.unmodifiable(
        (jsonDecode(raw) as List<dynamic>).map(PlannedMeal.tryParse).nonNulls,
      );
    } on Object {
      // Dữ liệu hỏng thì bỏ, không làm app lỗi.
      return const [];
    }
  }

  /// Xếp [recipeId] vào bữa [meal] ngày [day]; ô đã có món thì thay.
  Future<void> addToPlan(String recipeId, DateTime day, Meal meal) {
    final entry = PlannedMeal(day: day, meal: meal, recipeId: recipeId);
    return _save([..._without(entry.day, meal), entry]);
  }

  /// Bỏ món ở bữa [meal] ngày [day].
  Future<void> removeFromPlan(DateTime day, Meal meal) => _save(_without(dateOnly(day), meal));

  Iterable<PlannedMeal> _without(DateTime day, Meal meal) =>
      state.where((p) => p.day != day || p.meal != meal);

  Future<void> _save(Iterable<PlannedMeal> meals) async {
    state = List.unmodifiable(meals);
    await ref
        .read(localStoreProvider)
        .writeString(_mealsKey, jsonEncode([for (final p in state) p.toJson()]));
  }
}

/// Đọc: `ref.watch(plannedMealsProvider)`. Thêm từ màn khác:
/// `ref.read(plannedMealsProvider.notifier).addToPlan(recipeId, day, Meal.dinner)`.
final plannedMealsProvider = NotifierProvider<PlannedMealsController, List<PlannedMeal>>(
  PlannedMealsController.new,
);
