import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';

const _timerKey = 'system.notif.timer';
const _mealKey = 'system.notif.meal';

/// Công tắc thông báo trong Cài đặt. Mặc định bật nhắc hẹn giờ, tắt nhắc bữa (như prototype).
@immutable
class NotificationPrefs {
  const NotificationPrefs({this.timerDone = true, this.mealReminder = false});

  /// Báo khi đồng hồ nấu hết giờ.
  final bool timerDone;

  /// Nhắc bữa theo thực đơn.
  final bool mealReminder;

  @override
  bool operator ==(Object other) =>
      other is NotificationPrefs &&
      other.timerDone == timerDone &&
      other.mealReminder == mealReminder;

  @override
  int get hashCode => Object.hash(timerDone, mealReminder);
}

/// SYS-03: `NotificationService` bản thật đọc provider này để bỏ qua loại thông báo đã tắt.
class NotificationPrefsController extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() {
    final store = ref.watch(localStoreProvider);
    bool read(String key, bool fallback) => switch (store.readString(key)) {
      'true' => true,
      'false' => false,
      _ => fallback,
    };
    const defaults = NotificationPrefs();
    return NotificationPrefs(
      timerDone: read(_timerKey, defaults.timerDone),
      mealReminder: read(_mealKey, defaults.mealReminder),
    );
  }

  Future<void> setTimerDone(bool on) async {
    state = NotificationPrefs(timerDone: on, mealReminder: state.mealReminder);
    await ref.read(localStoreProvider).writeString(_timerKey, '$on');
  }

  Future<void> setMealReminder(bool on) async {
    state = NotificationPrefs(timerDone: state.timerDone, mealReminder: on);
    await ref.read(localStoreProvider).writeString(_mealKey, '$on');
  }
}

final notificationPrefsProvider = NotifierProvider<NotificationPrefsController, NotificationPrefs>(
  NotificationPrefsController.new,
);
