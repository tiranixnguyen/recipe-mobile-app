import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _mealsKey = 'plan.meals';

/// Giờ hiện tại; test override để cố định "hôm nay".
///
/// Đọc một lần khi màn dựng: để app mở qua nửa đêm thì "hôm nay" vẫn là ngày cũ tới khi màn dựng
/// lại (giới hạn đã biết, chưa cần theo dõi đổi ngày).
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

/// Bỏ giờ phút, chỉ giữ ngày (giờ địa phương).
DateTime dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

/// Một món đã xếp vào một bữa của một ngày, nấu cho [servings] người.
@immutable
class PlannedMeal {
  PlannedMeal({
    required DateTime day,
    required this.meal,
    required this.recipeId,
    this.servings = 1,
    this.cooked = false,
  }) : day = dateOnly(day);

  /// Luôn là 0h của ngày đó.
  final DateTime day;
  final Meal meal;
  final String recipeId;
  final int servings;

  /// Đã nấu xong cả bữa này (Nấu cả bữa).
  final bool cooked;

  Map<String, dynamic> toJson() => {
    'day': day.toIso8601String().substring(0, 10),
    'meal': meal.id,
    'recipeId': recipeId,
    'servings': servings,
    if (cooked) 'cooked': true,
  };

  /// Trả null khi bản ghi hỏng (thiếu trường, sai kiểu, bữa lạ), để chỉ mất bản ghi đó.
  ///
  /// [servings] thiếu, sai kiểu hoặc không dương thì coi là 1 (bản ghi cũ chưa có trường này).
  static PlannedMeal? tryParse(Object? json) {
    if (json case {'day': String day, 'meal': String meal, 'recipeId': String recipeId}) {
      final date = DateTime.tryParse(day);
      final parsedMeal = Meal.tryParse(meal);
      if (date == null || parsedMeal == null) return null;
      final servings = switch (json['servings']) {
        final int n when n > 0 => n,
        _ => 1,
      };
      return PlannedMeal(
        day: date,
        meal: parsedMeal,
        recipeId: recipeId,
        servings: servings,
        cooked: json['cooked'] == true,
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is PlannedMeal &&
      other.day == day &&
      other.meal == meal &&
      other.recipeId == recipeId &&
      other.servings == servings &&
      other.cooked == cooked;

  @override
  int get hashCode => Object.hash(day, meal, recipeId, servings, cooked);

  @override
  String toString() => 'PlannedMeal($day, $meal, $recipeId, $servings${cooked ? ', cooked' : ''})';
}

/// Thực đơn: mỗi bữa (ngày, bữa) có thể nhiều món (cơm + canh + mặn), theo thứ tự thêm.
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

  /// Thêm [recipeId] vào cuối bữa [meal] ngày [day], cho [servings] người.
  ///
  /// Món đã có trong bữa đó thì chỉ cập nhật khẩu phần, giữ vị trí và trạng thái đã nấu.
  Future<void> addToPlan(String recipeId, DateTime day, Meal meal, {int servings = 1}) {
    final entry = PlannedMeal(day: day, meal: meal, recipeId: recipeId, servings: servings);
    final index = state.indexWhere(
      (p) => p.day == entry.day && p.meal == meal && p.recipeId == recipeId,
    );
    if (index < 0) return _save([...state, entry]);
    final old = state[index];
    return _save(
      [...state]
        ..[index] = PlannedMeal(
          day: day,
          meal: meal,
          recipeId: recipeId,
          servings: servings,
          cooked: old.cooked,
        ),
    );
  }

  /// Đánh dấu mọi món trong bữa [meal] ngày [day] đã nấu (Nấu cả bữa xong).
  Future<void> markCooked(DateTime day, Meal meal) {
    final date = dateOnly(day);
    return _save([
      for (final p in state)
        p.day == date && p.meal == meal
            ? PlannedMeal(
                day: p.day,
                meal: p.meal,
                recipeId: p.recipeId,
                servings: p.servings,
                cooked: true,
              )
            : p,
    ]);
  }

  /// Bỏ món [recipeId] khỏi bữa [meal] ngày [day]; [recipeId] null thì bỏ cả bữa.
  Future<void> removeFromPlan(DateTime day, Meal meal, {String? recipeId}) {
    final date = dateOnly(day);
    return _save(
      state.where(
        (p) => p.day != date || p.meal != meal || (recipeId != null && p.recipeId != recipeId),
      ),
    );
  }

  Future<void> _save(Iterable<PlannedMeal> meals) async {
    state = List.unmodifiable(meals);
    await ref
        .read(localStoreProvider)
        .writeString(_mealsKey, jsonEncode([for (final p in state) p.toJson()]));
  }
}

/// Đọc: `ref.watch(plannedMealsProvider)`. Thêm từ màn khác:
/// `ref.read(plannedMealsProvider.notifier).addToPlan(recipeId, day, Meal.dinner, servings: 2)`.
final plannedMealsProvider = NotifierProvider<PlannedMealsController, List<PlannedMeal>>(
  PlannedMealsController.new,
);
