import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';

/// Gửi thông báo trên máy. F2 gọi [timerDone] khi hẹn giờ nấu hết, F4 gọi [mealReminder] để nhắc
/// bữa theo thực đơn.
///
/// Hiện là stub ([NoopNotificationService]). SYS-03 thay bằng bản `flutter_local_notifications`, tự
/// bỏ qua khi người dùng tắt công tắc tương ứng trong Cài đặt; chữ ký giữ nguyên.
abstract interface class NotificationService {
  /// Báo đồng hồ nấu của món [recipeTitle] đã hết giờ.
  Future<void> timerDone({required String recipeTitle});

  /// Hẹn nhắc bữa [meal] lúc [at] cho món [recipeTitle].
  Future<void> mealReminder({
    required Meal meal,
    required DateTime at,
    required String recipeTitle,
  });
}

/// Không làm gì; dùng tới khi có SYS-03 và trong test.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> timerDone({required String recipeTitle}) async {}

  @override
  Future<void> mealReminder({
    required Meal meal,
    required DateTime at,
    required String recipeTitle,
  }) async {}
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => const NoopNotificationService(),
);
