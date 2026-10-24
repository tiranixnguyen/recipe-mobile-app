import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _shoppingKey = 'plan.shopping';

/// Yêu cầu đi chợ cho một món với số khẩu phần.
@immutable
class ShoppingRequest {
  const ShoppingRequest({required this.recipeId, required this.servings});

  final String recipeId;
  final int servings;

  Map<String, dynamic> toJson() => {'recipeId': recipeId, 'servings': servings};

  /// Trả null khi bản ghi hỏng.
  static ShoppingRequest? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final recipeId = json['recipeId'];
    final servings = json['servings'];
    if (recipeId is! String || servings is! int || servings <= 0) return null;
    return ShoppingRequest(recipeId: recipeId, servings: servings);
  }

  @override
  bool operator ==(Object other) =>
      other is ShoppingRequest && other.recipeId == recipeId && other.servings == servings;

  @override
  int get hashCode => Object.hash(recipeId, servings);

  @override
  String toString() => 'ShoppingRequest($recipeId, $servings)';
}

/// Món người dùng muốn đi chợ (từ Chi tiết món, Thực đơn).
///
/// Stub (PLAN-00): chỉ lưu yêu cầu theo thứ tự thêm, mỗi món một dòng. SHP-01 tính danh sách
/// nguyên liệu thật (gộp, trừ đồ trong Tủ đồ), giữ nguyên `addToShopping`.
class ShoppingController extends Notifier<List<ShoppingRequest>> {
  @override
  List<ShoppingRequest> build() {
    final raw = ref.watch(localStoreProvider).readString(_shoppingKey);
    if (raw == null) return const [];
    try {
      return List.unmodifiable(
        (jsonDecode(raw) as List<dynamic>).map(ShoppingRequest.tryParse).nonNulls,
      );
    } on Object {
      // Dữ liệu hỏng thì bỏ, không làm app lỗi.
      return const [];
    }
  }

  /// Thêm [recipeId] cho [servings] người; món đã có thì cập nhật khẩu phần.
  Future<void> addToShopping(String recipeId, int servings) async {
    final request = ShoppingRequest(recipeId: recipeId, servings: servings);
    final index = state.indexWhere((r) => r.recipeId == recipeId);
    state = List.unmodifiable(
      index < 0 ? [...state, request] : ([...state]..[index] = request),
    );
    await ref
        .read(localStoreProvider)
        .writeString(_shoppingKey, jsonEncode([for (final r in state) r.toJson()]));
  }
}

/// Đọc: `ref.watch(shoppingProvider)`. Thêm:
/// `ref.read(shoppingProvider.notifier).addToShopping(recipeId, 2)`.
final shoppingProvider = NotifierProvider<ShoppingController, List<ShoppingRequest>>(
  ShoppingController.new,
);
