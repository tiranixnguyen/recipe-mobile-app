import 'package:recipe_mobile_app/core/models/models.dart';
import 'package:recipe_mobile_app/features/cook/data/cook_device.dart';
import 'package:recipe_mobile_app/features/system/system.dart';

class FakeWakelock implements ScreenWakelock {
  bool enabled = false;

  @override
  Future<void> enable() async => enabled = true;

  @override
  Future<void> disable() async => enabled = false;
}

/// Ghi lại lịch báo hết giờ đang hẹn, theo key.
class FakeNotificationService implements NotificationService {
  final timers = <int, ({String recipeTitle, DateTime at})>{};

  @override
  Future<void> scheduleTimer({
    required int key,
    required String recipeTitle,
    required DateTime at,
  }) async => timers[key] = (recipeTitle: recipeTitle, at: at);

  @override
  Future<void> cancelTimer(int key) async => timers.remove(key);

  @override
  Future<void> timerDone({required String recipeTitle}) async {}

  @override
  Future<void> mealReminder({
    required Meal meal,
    required DateTime at,
    required String recipeTitle,
  }) async {}

  @override
  Future<void> cancelMealReminders() async {}
}
