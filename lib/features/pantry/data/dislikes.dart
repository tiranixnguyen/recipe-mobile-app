import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _dislikedKey = 'pantry.disliked';

/// Lý do chê món ở màn Hôm nay ăn gì (prototype `Today`).
enum DislikeReason {
  justAte('justAte', 'Vừa ăn rồi'),
  missingIngredients('missingIngredients', 'Thiếu đồ'),
  tooLong('tooLong', 'Lâu quá'),
  notMyTaste('notMyTaste', 'Không hợp khẩu vị');

  const DislikeReason(this.id, this.label);

  final String id;
  final String label;

  /// Đọc id từ `LocalStore`; trả null để bỏ qua dữ liệu cũ không còn hợp lệ.
  static DislikeReason? tryParse(String? value) {
    for (final reason in values) {
      if (reason.id == value) return reason;
    }
    return null;
  }
}

/// Một lần chê món: lý do và lúc chê (gợi ý có thể cho món "Vừa ăn rồi" quay lại sau vài ngày).
@immutable
class Dislike {
  const Dislike({required this.reason, required this.at});

  final DislikeReason reason;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Dislike && other.reason == reason && other.at == at;

  @override
  int get hashCode => Object.hash(reason, at);

  @override
  String toString() => 'Dislike($reason, $at)';
}

/// Món đã chê, theo id món; chê lại thì ghi đè lần trước.
class DislikesController extends Notifier<Map<String, Dislike>> {
  @override
  Map<String, Dislike> build() {
    final raw = ref.watch(localStoreProvider).readString(_dislikedKey);
    if (raw == null) return const {};
    final result = <String, Dislike>{};
    try {
      for (final MapEntry(:key, :value) in (jsonDecode(raw) as Map<String, dynamic>).entries) {
        final json = value as Map<String, dynamic>;
        final reason = DislikeReason.tryParse(json['reason'] as String?);
        final at = DateTime.tryParse(json['at'] as String? ?? '');
        if (reason != null && at != null) result[key] = Dislike(reason: reason, at: at);
      }
    } on Object {
      // Dữ liệu hỏng thì bỏ, không làm app lỗi.
      return const {};
    }
    return Map.unmodifiable(result);
  }

  Future<void> dislike(String recipeId, DislikeReason reason, {DateTime? at}) async {
    state = Map.unmodifiable({
      ...state,
      recipeId: Dislike(reason: reason, at: at ?? DateTime.now()),
    });
    await ref
        .read(localStoreProvider)
        .writeString(
          _dislikedKey,
          jsonEncode({
            for (final MapEntry(:key, :value) in state.entries)
              key: {'reason': value.reason.id, 'at': value.at.toIso8601String()},
          }),
        );
  }
}

/// Đọc: `ref.watch(dislikedProvider)`. Chê:
/// `ref.read(dislikedProvider.notifier).dislike(recipeId, DislikeReason.tooLong)`.
final dislikedProvider = NotifierProvider<DislikesController, Map<String, Dislike>>(
  DislikesController.new,
);
