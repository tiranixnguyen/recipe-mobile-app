import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/system/data/notification_plugin.dart';
import 'package:recipe_mobile_app/features/system/data/notification_prefs.dart';
import 'package:recipe_mobile_app/features/system/strings.dart';

/// Gửi thông báo trên máy. F2 hẹn [scheduleTimer] khi đồng hồ nấu bắt đầu chạy (báo cả khi đang ở
/// app khác), huỷ bằng [cancelTimer]; [timerDone] báo ngay. Nhắc bữa theo thực đơn do
/// feature Hệ thống tự hẹn (`mealReminderSyncProvider`), dùng [mealReminder].
///
/// Bản thật ([LocalNotificationService]) tự bỏ qua khi người dùng tắt công tắc tương ứng trong
/// Cài đặt.
abstract interface class NotificationService {
  /// Báo đồng hồ nấu của món [recipeTitle] đã hết giờ.
  Future<void> timerDone({required String recipeTitle});

  /// Hẹn báo hết giờ của món [recipeTitle] lúc [at]. [key] (0…[maxTimerKey]) phân biệt các đồng hồ
  /// chạy cùng lúc (nấu cả bữa); hẹn lại cùng [key] thì thay lịch cũ.
  Future<void> scheduleTimer({required int key, required String recipeTitle, required DateTime at});

  /// Huỷ báo hết giờ đã hẹn với [key].
  Future<void> cancelTimer(int key);

  /// Hẹn nhắc bữa [meal] lúc [at] cho món [recipeTitle]. Hẹn lại cùng ngày và bữa thì thay lịch cũ.
  Future<void> mealReminder({
    required Meal meal,
    required DateTime at,
    required String recipeTitle,
  });

  /// Huỷ mọi lời nhắc bữa đã hẹn.
  Future<void> cancelMealReminders();
}

/// [NotificationService.scheduleTimer] nhận key từ 0 tới số này.
const maxTimerKey = 899;

/// Không làm gì; dùng trong test của feature khác.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> timerDone({required String recipeTitle}) async {}

  @override
  Future<void> scheduleTimer({
    required int key,
    required String recipeTitle,
    required DateTime at,
  }) async {}

  @override
  Future<void> cancelTimer(int key) async {}

  @override
  Future<void> mealReminder({
    required Meal meal,
    required DateTime at,
    required String recipeTitle,
  }) async {}

  @override
  Future<void> cancelMealReminders() async {}
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService(this._plugin, {required this._prefs});

  final NotificationPlugin _plugin;
  final NotificationPrefs Function() _prefs;

  /// Báo hết giờ ngay ([timerDone]) dùng chung một id: thông báo mới thay thông báo cũ.
  static const timerId = 1;

  /// Id báo hết giờ đã hẹn: [_timerIdBase] + key, nằm dưới id nhắc bữa.
  static const _timerIdBase = 100;

  static int scheduledTimerId(int key) {
    RangeError.checkValueInInterval(key, 0, maxTimerKey, 'key');
    return _timerIdBase + key;
  }

  /// Id nhắc bữa: một id cho mỗi (ngày, bữa), từ [_mealIdBase] trở lên.
  static const _mealIdBase = 1000;

  static int mealReminderId(DateTime at, Meal meal) {
    final day = DateTime.utc(at.year, at.month, at.day);
    final days = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return _mealIdBase + days * Meal.values.length + meal.index;
  }

  static bool _isMealReminder(int id) => id >= _mealIdBase;

  @override
  Future<void> timerDone({required String recipeTitle}) async {
    if (!_prefs().timerDone) return;
    await _plugin.show(
      id: timerId,
      channel: NotificationChannel.timer,
      title: SystemStrings.notifTimerTitle,
      body: SystemStrings.notifTimerBody(recipeTitle),
    );
  }

  @override
  Future<void> scheduleTimer({
    required int key,
    required String recipeTitle,
    required DateTime at,
  }) async {
    final id = scheduledTimerId(key);
    if (!_prefs().timerDone || !at.isAfter(DateTime.now())) return;
    await _plugin.schedule(
      id: id,
      channel: NotificationChannel.timer,
      at: at,
      title: SystemStrings.notifTimerTitle,
      body: SystemStrings.notifTimerBody(recipeTitle),
    );
  }

  @override
  Future<void> cancelTimer(int key) => _plugin.cancel(scheduledTimerId(key));

  @override
  Future<void> mealReminder({
    required Meal meal,
    required DateTime at,
    required String recipeTitle,
  }) async {
    if (!_prefs().mealReminder || !at.isAfter(DateTime.now())) return;
    await _plugin.schedule(
      id: mealReminderId(at, meal),
      channel: NotificationChannel.meal,
      at: at,
      title: SystemStrings.notifMealTitle(meal),
      body: SystemStrings.notifMealBody(recipeTitle),
    );
  }

  @override
  Future<void> cancelMealReminders() async {
    for (final id in await _plugin.pendingIds()) {
      if (_isMealReminder(id)) await _plugin.cancel(id);
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => LocalNotificationService(
    ref.watch(notificationPluginProvider),
    prefs: () => ref.read(notificationPrefsProvider),
  ),
);
