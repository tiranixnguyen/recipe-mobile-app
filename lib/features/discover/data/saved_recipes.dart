import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _savedKey = 'discover.saved';
const _savedAtKey = 'discover.savedAt';

/// Giờ hiện tại khi lưu món/bữa; test override để cố định.
final savedClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Id món đã lưu, theo thứ tự lưu (cũ trước, mới sau).
class SavedRecipesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => Set.unmodifiable(ref.watch(localStoreProvider).readList(_savedKey));

  /// Lưu nếu chưa lưu, bỏ lưu nếu đã lưu.
  Future<void> toggle(String recipeId) =>
      state.contains(recipeId) ? unsave(recipeId) : save(recipeId);

  /// Lưu một món nếu chưa lưu; [at] giữ lại giờ lưu cũ khi Hoàn tác.
  Future<void> save(String recipeId, {DateTime? at}) async {
    if (state.contains(recipeId)) return;
    await _write({...state, recipeId});
    await ref.read(savedAtProvider.notifier)._set(recipeId, at ?? ref.read(savedClockProvider)());
  }

  /// Bỏ lưu một món nếu đang lưu.
  Future<void> unsave(String recipeId) async {
    if (!state.contains(recipeId)) return;
    await _write({...state}..remove(recipeId));
    await ref.read(savedAtProvider.notifier)._set(recipeId, null);
  }

  Future<void> _write(Set<String> next) async {
    state = Set.unmodifiable(next);
    await ref.read(localStoreProvider).writeList(_savedKey, next.toList());
  }
}

/// Đọc: `ref.watch(savedIdsProvider).contains(id)`. Đổi:
/// `ref.read(savedIdsProvider.notifier).toggle(id)`; trên giao diện dùng `SaveButton`.
final savedIdsProvider = NotifierProvider<SavedRecipesController, Set<String>>(
  SavedRecipesController.new,
);

/// Giờ lưu từng món (id → giờ). Món lưu trước khi có key này thì không có giờ.
class SavedAtController extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    final raw = ref.watch(localStoreProvider).readString(_savedAtKey);
    if (raw == null) return const {};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Map.unmodifiable({
        for (final MapEntry(:key, :value) in json.entries)
          if (value is String) key: ?DateTime.tryParse(value),
      });
    } catch (_) {
      return const {};
    }
  }

  Future<void> _set(String recipeId, DateTime? at) async {
    final next = {...state};
    if (at == null) {
      next.remove(recipeId);
    } else {
      next[recipeId] = at;
    }
    state = Map.unmodifiable(next);
    await ref
        .read(localStoreProvider)
        .writeString(
          _savedAtKey,
          jsonEncode({for (final e in next.entries) e.key: e.value.toIso8601String()}),
        );
  }
}

/// Giờ lưu của món đã lưu; ghi qua [SavedRecipesController].
final savedAtProvider = NotifierProvider<SavedAtController, Map<String, DateTime>>(
  SavedAtController.new,
);
