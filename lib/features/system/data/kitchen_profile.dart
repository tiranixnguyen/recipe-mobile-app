import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _toolsKey = 'system.tools';
const _dietsKey = 'system.diets';

/// Dụng cụ trong phòng và chế độ ăn, chọn ở Onboarding và sửa trong Cài đặt.
///
/// Set rỗng nghĩa là người dùng **chưa chọn** (bỏ qua Onboarding), không phải "không có dụng cụ
/// nào"; feature dùng (F3 gợi ý) tự quyết cách lọc khi rỗng.
@immutable
class KitchenProfile {
  const KitchenProfile({this.tools = const {}, this.diets = const {}});

  final Set<Tool> tools;
  final Set<Diet> diets;

  KitchenProfile copyWith({Set<Tool>? tools, Set<Diet>? diets}) =>
      KitchenProfile(tools: tools ?? this.tools, diets: diets ?? this.diets);

  @override
  bool operator ==(Object other) =>
      other is KitchenProfile && setEquals(other.tools, tools) && setEquals(other.diets, diets);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(tools), Object.hashAllUnordered(diets));

  @override
  String toString() => 'KitchenProfile(tools: $tools, diets: $diets)';
}

class KitchenProfileController extends Notifier<KitchenProfile> {
  @override
  KitchenProfile build() {
    final store = ref.watch(localStoreProvider);
    return KitchenProfile(
      tools: Set.unmodifiable(store.readList(_toolsKey).map(Tool.tryParse).nonNulls),
      diets: Set.unmodifiable(store.readList(_dietsKey).map(Diet.tryParse).nonNulls),
    );
  }

  Future<void> save(KitchenProfile profile) async {
    state = KitchenProfile(
      tools: Set.unmodifiable(profile.tools),
      diets: Set.unmodifiable(profile.diets),
    );
    final store = ref.read(localStoreProvider);
    await store.writeList(_toolsKey, [for (final tool in profile.tools) tool.id]);
    await store.writeList(_dietsKey, [for (final diet in profile.diets) diet.id]);
  }
}

final kitchenProfileProvider = NotifierProvider<KitchenProfileController, KitchenProfile>(
  KitchenProfileController.new,
);
