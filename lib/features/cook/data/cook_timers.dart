import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/widgets/step_timer.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_session.dart';
import 'package:recipe_mobile_app/features/cook/domain/cook_step.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

/// Giữ lịch báo hết giờ và mốc hết giờ trong phiên nấu khớp với `StepTimer` trên màn.
class CookTimers {
  CookTimers(this._ref);

  final Ref _ref;

  /// `StepTimer` của bước [step] món thứ [dish] đổi trạng thái.
  ///
  /// - Đang chạy: hẹn báo hết giờ (báo cả khi ở app khác), lưu mốc vào phiên. Chạy tiếp từ mốc đã
  ///   lưu ([savedEnd], khi mở lại màn) thì giữ mốc đó.
  /// - Dừng: huỷ lịch, bỏ mốc.
  /// - Hết giờ: bỏ mốc; app đang mở thì huỷ lịch (người dùng đã thấy trên màn).
  Future<void> changed({
    required int dish,
    required int step,
    required StepTimerStatus status,
    required String recipeTitle,
    required int seconds,
    DateTime? savedEnd,
  }) async {
    final notifications = _ref.read(notificationServiceProvider);
    final sessions = _ref.read(cookSessionProvider.notifier);
    final key = cookTimerKey(dish, step);
    switch (status) {
      case StepTimerStatus.running:
        final at = savedEnd ?? _ref.read(cookClockProvider)().add(Duration(seconds: seconds));
        await notifications.scheduleTimer(key: key, recipeTitle: recipeTitle, at: at);
        await sessions.setTimerEnd(key, at);
      case StepTimerStatus.idle:
        await notifications.cancelTimer(key);
        await sessions.setTimerEnd(key, null);
      case StepTimerStatus.done:
        if (_ref.read(appInForegroundProvider)()) await notifications.cancelTimer(key);
        await sessions.setTimerEnd(key, null);
    }
  }

  /// Huỷ lịch và mốc của các bước [steps] món thứ [dish] (nấu xong món).
  Future<void> cancel(int dish, Iterable<int> steps) async {
    final notifications = _ref.read(notificationServiceProvider);
    final sessions = _ref.read(cookSessionProvider.notifier);
    for (final step in steps) {
      await notifications.cancelTimer(cookTimerKey(dish, step));
      await sessions.setTimerEnd(cookTimerKey(dish, step), null);
    }
  }
}

final cookTimersProvider = Provider<CookTimers>(CookTimers.new);
