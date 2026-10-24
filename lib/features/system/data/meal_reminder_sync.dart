import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recipe_mobile_app/core/data/recipe_repository.dart';
import 'package:recipe_mobile_app/features/plan/plan.dart';
import 'package:recipe_mobile_app/features/system/data/notification_prefs.dart';
import 'package:recipe_mobile_app/features/system/data/notification_service.dart';
import 'package:recipe_mobile_app/features/system/domain/meal_reminders.dart';

/// Hẹn lại toàn bộ nhắc bữa mỗi khi thực đơn, công tắc hoặc giờ nhắc đổi, và mỗi lần mở app.
///
/// `App` chỉ cần `ref.listen` provider này. Giá trị là lần hẹn mới nhất (test `await` được).
final mealReminderSyncProvider = Provider<Future<void>>((ref) {
  final prefs = ref.watch(notificationPrefsProvider);
  final planned = ref.watch(plannedMealsProvider);
  final recipes = ref.watch(recipesProvider).value;
  final service = ref.watch(notificationServiceProvider);
  final queue = ref.watch(_mealReminderQueueProvider);
  // Chưa đọc xong công thức thì chưa có tên món; đọc xong provider tự chạy lại.
  if (recipes == null) return queue.last;

  final titles = {for (final recipe in recipes) recipe.id: recipe.name};
  final reminders = prefs.mealReminder
      ? mealReminders(
          planned: [
            for (final p in planned)
              if (titles[p.recipeId] case final title?)
                (day: p.day, meal: p.meal, recipeTitle: title),
          ],
          now: DateTime.now(),
          lead: prefs.mealReminderLead,
        )
      : const <MealReminder>[];

  return queue.add(() async {
    await service.cancelMealReminders();
    for (final r in reminders) {
      await service.mealReminder(meal: r.meal, at: r.at, recipeTitle: r.recipeTitle);
    }
  });
});

/// Chạy lần lượt các lần hẹn lại, để lần cũ chưa xong không ghi đè lần mới.
class _SerialQueue {
  Future<void> last = Future.value();

  Future<void> add(Future<void> Function() job) => last = last.then((_) => job()).catchError((
    Object error,
    StackTrace stack,
  ) {
    // Hẹn thông báo lỗi (bị chặn quyền, plugin lỗi) không được làm hỏng app.
    debugPrint('Không hẹn được nhắc bữa: $error');
  });
}

final _mealReminderQueueProvider = Provider<_SerialQueue>((ref) => _SerialQueue());
