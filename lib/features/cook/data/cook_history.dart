import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _historyKey = 'cook.history';

/// Đánh giá sau khi nấu xong (prototype `CookDone`).
enum CookRating {
  good('good', 'Ngon'),
  ok('ok', 'Tạm'),
  bad('bad', 'Chê');

  const CookRating(this.id, this.label);

  final String id;
  final String label;

  /// Đọc id từ `LocalStore`; trả null để bỏ qua dữ liệu cũ không còn hợp lệ.
  static CookRating? tryParse(String? value) {
    for (final rating in values) {
      if (rating.id == value) return rating;
    }
    return null;
  }
}

/// Một lần nấu xong một món.
@immutable
class CookRecord {
  const CookRecord({required this.recipeId, required this.cookedAt, this.rating});

  final String recipeId;
  final DateTime cookedAt;

  /// Null khi người dùng bỏ qua bước đánh giá.
  final CookRating? rating;

  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    'cookedAt': cookedAt.toIso8601String(),
    if (rating != null) 'rating': rating!.id,
  };

  /// Trả null khi bản ghi hỏng (thiếu trường, sai kiểu); đánh giá lạ thì bỏ riêng đánh giá.
  static CookRecord? tryParse(Object? json) {
    if (json case {'recipeId': String recipeId, 'cookedAt': String cookedAt}) {
      final at = DateTime.tryParse(cookedAt);
      if (at == null) return null;
      final rating = json['rating'];
      return CookRecord(
        recipeId: recipeId,
        cookedAt: at,
        rating: rating is String ? CookRating.tryParse(rating) : null,
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CookRecord &&
      other.recipeId == recipeId &&
      other.cookedAt == cookedAt &&
      other.rating == rating;

  @override
  int get hashCode => Object.hash(recipeId, cookedAt, rating);

  @override
  String toString() => 'CookRecord($recipeId, $cookedAt, $rating)';
}

/// Lịch sử nấu, cũ trước mới sau.
class CookHistoryController extends Notifier<List<CookRecord>> {
  @override
  List<CookRecord> build() {
    final raw = ref.watch(localStoreProvider).readString(_historyKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return List.unmodifiable(list.map(CookRecord.tryParse).nonNulls);
    } on Object {
      // Dữ liệu hỏng thì bỏ, không làm app lỗi.
      return const [];
    }
  }

  /// Ghi một lần nấu xong; [at] mặc định là bây giờ.
  Future<void> record(String recipeId, {CookRating? rating, DateTime? at}) async {
    state = List.unmodifiable([
      ...state,
      CookRecord(recipeId: recipeId, cookedAt: at ?? DateTime.now(), rating: rating),
    ]);
    await ref
        .read(localStoreProvider)
        .writeString(_historyKey, jsonEncode([for (final r in state) r.toJson()]));
  }
}

/// Đọc: `ref.watch(cookHistoryProvider)`. Ghi ở màn Nấu xong:
/// `ref.read(cookHistoryProvider.notifier).record(recipeId, rating: CookRating.good)`.
final cookHistoryProvider = NotifierProvider<CookHistoryController, List<CookRecord>>(
  CookHistoryController.new,
);
