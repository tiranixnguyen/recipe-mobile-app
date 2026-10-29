import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/core/text/fold.dart';

const _itemsKey = 'plan.shoppingItems';

/// Một thứ người dùng tự thêm vào đi chợ (từ Tủ đồ): nguyên liệu trong danh mục ([ingredientId])
/// hoặc tên tự gõ ([name]), đúng một trong hai.
@immutable
class ShoppingItem {
  const ShoppingItem.ingredient(String this.ingredientId) : name = null;

  const ShoppingItem.custom(String this.name) : ingredientId = null;

  final String? ingredientId;
  final String? name;

  Map<String, dynamic> toJson() => {
    'ingredientId': ?ingredientId,
    'name': ?name,
  };

  /// Trả null khi bản ghi hỏng (thiếu cả hai trường, sai kiểu, chuỗi rỗng).
  static ShoppingItem? tryParse(Object? json) => switch (json) {
    {'ingredientId': String id} when id.isNotEmpty => ShoppingItem.ingredient(id),
    {'name': String name} when name.trim().isNotEmpty => ShoppingItem.custom(name.trim()),
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is ShoppingItem && other.ingredientId == ingredientId && other.name == name;

  @override
  int get hashCode => Object.hash(ingredientId, name);

  @override
  String toString() => 'ShoppingItem(${ingredientId ?? '"$name"'})';
}

enum AddToShoppingResult { added, alreadyThere }

/// Đồ người dùng tự thêm vào đi chợ, theo thứ tự thêm.
///
/// Stub cho SHP-01 (#49): chỉ lưu danh sách, chưa gộp với nguyên liệu của món trong thực đơn và chưa
/// có trạng thái đã mua. #49 làm màn Đi chợ và logic gộp, giữ nguyên chữ ký các method.
class ShoppingItemsController extends Notifier<List<ShoppingItem>> {
  @override
  List<ShoppingItem> build() {
    final raw = ref.watch(localStoreProvider).readString(_itemsKey);
    if (raw == null) return const [];
    try {
      return List.unmodifiable(
        (jsonDecode(raw) as List<dynamic>).map(ShoppingItem.tryParse).nonNulls.toSet(),
      );
    } on Object {
      // Dữ liệu hỏng thì bỏ, không làm app lỗi.
      return const [];
    }
  }

  /// Thêm nguyên liệu [ingredientId]; đã có trong danh sách thì không thêm lần nữa.
  ///
  /// Không kiểm tra Tủ đồ: chặn thêm đồ đang có trong tủ là việc của nơi gọi.
  Future<AddToShoppingResult> addIngredient(String ingredientId) =>
      _add(ShoppingItem.ingredient(ingredientId));

  /// Thêm tên tự gõ [name]; trùng (bỏ dấu, không phân biệt hoa thường) với tên đã có thì không thêm.
  Future<AddToShoppingResult> addCustom(String name) {
    final folded = normalizeSearch(name);
    if (state.any((i) => i.name != null && normalizeSearch(i.name!) == folded)) {
      return Future.value(AddToShoppingResult.alreadyThere);
    }
    return _add(ShoppingItem.custom(name.trim()));
  }

  /// Bỏ [item] (Hoàn tác, đã mua); không có thì thôi.
  Future<void> remove(ShoppingItem item) async {
    if (!state.contains(item)) return;
    await _save([...state]..remove(item));
  }

  Future<AddToShoppingResult> _add(ShoppingItem item) async {
    if (state.contains(item)) return AddToShoppingResult.alreadyThere;
    await _save([...state, item]);
    return AddToShoppingResult.added;
  }

  Future<void> _save(List<ShoppingItem> items) async {
    state = List.unmodifiable(items);
    await ref
        .read(localStoreProvider)
        .writeString(_itemsKey, jsonEncode([for (final i in items) i.toJson()]));
  }
}

/// Đọc: `ref.watch(shoppingItemsProvider)`. Thêm:
/// `ref.read(shoppingItemsProvider.notifier).addIngredient('egg')`.
final shoppingItemsProvider = NotifierProvider<ShoppingItemsController, List<ShoppingItem>>(
  ShoppingItemsController.new,
);

/// Số trên badge nút Đi chợ. Tạm thời là số đồ tự thêm; #49 đổi thành số dòng chưa tick.
final shoppingCountProvider = Provider<int>((ref) => ref.watch(shoppingItemsProvider).length);
