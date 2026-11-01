import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_history.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';

const _askedAtKey = 'cook.reviewAskedAt';

/// Hộp đánh giá của Google Play (prototype `RateApp`); test thay bằng bản giả.
abstract interface class AppReview {
  /// Xin hệ thống hiện hộp đánh giá. Google Play tự quyết có hiện hay không, app không biết kết quả.
  Future<void> request();
}

/// Bản thật dùng `in_app_review`. Lỗi (máy không có Google Play) thì bỏ qua.
class PlayAppReview implements AppReview {
  const PlayAppReview();

  @override
  Future<void> request() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } on Object {
      // Bỏ qua, xem doc của class.
    }
  }
}

final appReviewProvider = Provider<AppReview>((ref) => const PlayAppReview());

/// Hỏi đánh giá app sau vài lần nấu ngon, không hỏi lại liên tục.
class ReviewPrompt {
  ReviewPrompt(this._ref);

  final Ref _ref;

  /// Tổng số lần chấm "Ngon" để hỏi lần đầu.
  static const goodRatings = 3;

  /// Đã hỏi thì chừng này ngày sau mới hỏi lại.
  static const askAgainAfter = Duration(days: 90);

  /// Gọi sau khi ghi đánh giá vào [cookHistoryProvider]: đủ [goodRatings] lần "Ngon" và chưa hỏi
  /// trong [askAgainAfter] thì xin hiện hộp đánh giá, ghi lại lúc hỏi.
  Future<void> maybeAsk() async {
    final good = _ref
        .read(cookHistoryProvider)
        .expand((e) => e.dishes)
        .where((d) => d.rating == CookRating.good)
        .length;
    if (good < goodRatings) return;
    final store = _ref.read(localStoreProvider);
    final now = _ref.read(cookClockProvider)();
    final askedAt = DateTime.tryParse(store.readString(_askedAtKey) ?? '');
    if (askedAt != null && now.difference(askedAt) < askAgainAfter) return;
    await store.writeString(_askedAtKey, now.toIso8601String());
    await _ref.read(appReviewProvider).request();
  }
}

final reviewPromptProvider = Provider<ReviewPrompt>(ReviewPrompt.new);
