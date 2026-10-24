import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/storage/local_store.dart';

const _timerKey = 'system.notif.timer';
const _mealKey = 'system.notif.meal';
const _mealLeadKey = 'system.notif.mealLead';

/// Công tắc thông báo trong Cài đặt. Mặc định bật nhắc hẹn giờ, tắt nhắc bữa (như prototype).
@immutable
class NotificationPrefs {
  const NotificationPrefs({
    this.timerDone = true,
    this.mealReminder = false,
    this.mealReminderLead = const Duration(minutes: 30),
  });

  /// Các lựa chọn "nhắc trước bữa bao lâu" trong Cài đặt.
  static const mealReminderLeads = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
  ];

  /// Báo khi đồng hồ nấu hết giờ.
  final bool timerDone;

  /// Nhắc bữa theo thực đơn.
  final bool mealReminder;

  /// Nhắc trước giờ bữa bao lâu, một trong [mealReminderLeads].
  final Duration mealReminderLead;

  NotificationPrefs copyWith({bool? timerDone, bool? mealReminder, Duration? mealReminderLead}) =>
      NotificationPrefs(
        timerDone: timerDone ?? this.timerDone,
        mealReminder: mealReminder ?? this.mealReminder,
        mealReminderLead: mealReminderLead ?? this.mealReminderLead,
      );

  @override
  bool operator ==(Object other) =>
      other is NotificationPrefs &&
      other.timerDone == timerDone &&
      other.mealReminder == mealReminder &&
      other.mealReminderLead == mealReminderLead;

  @override
  int get hashCode => Object.hash(timerDone, mealReminder, mealReminderLead);
}

/// `NotificationService` đọc provider này để bỏ qua loại thông báo đã tắt.
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
    final leadMinutes = int.tryParse(store.readString(_mealLeadKey) ?? '');
    final lead = NotificationPrefs.mealReminderLeads.firstWhere(
      (d) => d.inMinutes == leadMinutes,
      orElse: () => defaults.mealReminderLead,
    );
    return NotificationPrefs(
      timerDone: read(_timerKey, defaults.timerDone),
      mealReminder: read(_mealKey, defaults.mealReminder),
      mealReminderLead: lead,
    );
  }

  Future<void> setTimerDone(bool on) async {
    state = state.copyWith(timerDone: on);
    await ref.read(localStoreProvider).writeString(_timerKey, '$on');
  }

  Future<void> setMealReminder(bool on) async {
    state = state.copyWith(mealReminder: on);
    await ref.read(localStoreProvider).writeString(_mealKey, '$on');
  }

  Future<void> setMealReminderLead(Duration lead) async {
    state = state.copyWith(mealReminderLead: lead);
    await ref.read(localStoreProvider).writeString(_mealLeadKey, '${lead.inMinutes}');
  }
}

final notificationPrefsProvider = NotifierProvider<NotificationPrefsController, NotificationPrefs>(
  NotificationPrefsController.new,
);
